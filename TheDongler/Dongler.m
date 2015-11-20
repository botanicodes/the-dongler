//
//  Dongler.m
//  Dongler
//
//  Created by Joseph Rivard on 11/18/15.
//  Copyright © 2015 LiftMaster. All rights reserved.
//

#import "Dongler.h"

@interface Dongler()

@property Dongle* connectedDongle;
@property CBCentralManager* centralManager;

// scanning properties
@property dispatch_queue_t scanQueue;
@property dispatch_semaphore_t scanSem;
@property (strong) DonglerFoundDongle scanDongleFoundAction;

// connecting properties
@property (strong) DonglerActionComplete connectedToDongleAction;
@property NSLock* connectingToDongleLock;
@property Dongle* currentDongle;

// disconnection properties
@property (strong) DonglerActionComplete disconnectedFromDongleAction;

@end

@implementation Dongler

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if(!self) return self;
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    _scanSem   = dispatch_semaphore_create(0);
    _scanQueue = dispatch_queue_create("donglerScanQueue", 0);
    _connectingToDongleLock = [[NSLock alloc] init];
    
    return self;
}

#pragma mark - CB delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Dongler status %lu", central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // invoke the current dongle found block
        self.scanDongleFoundAction([Dongle withPeripheral:peripheral]);
        
        // tell listDonglesWithSerices: that a new dongle has been found so it doesn't time out yet
        dispatch_semaphore_signal(self.scanSem);
    });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.currentDongle interrogate];
    //[peripheral discoverServices:nil];
    self.connectedToDongleAction(nil);
    [self.connectingToDongleLock unlock];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.connectedToDongleAction(error);
    [self.connectingToDongleLock unlock];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if(self.disconnectedFromDongleAction){
        self.disconnectedFromDongleAction(error);
    }
    else{
        NSLog(@"Disconnected with no completion block: %@", error.description);
    }
}

#pragma mark - Class methods

+ (Dongler*)sharedDongler
{
    static Dongler* dongler;
    
    if(!dongler){ // dongler hasn't been allocated yet
        dongler = [[Dongler alloc] init];
    }
    
    return dongler;
}

+ (void)prepare
{
    [Dongler sharedDongler];
}

+ (Dongle *)connectedDongle
{
    return [self sharedDongler].connectedDongle;
}

+ (void)listDonglesWithServices:(NSArray<CBUUID*>*)services
                    foundDongle:(DonglerFoundDongle)foundDongle
                 withCompletion:(DonglerActionComplete)complete
{
    Dongler* dongler = [self sharedDongler];
    
    // make sure bluetooth is on and we are ready to start interacting with it
    if(dongler.centralManager.state != CBCentralManagerStatePoweredOn){
        complete([NSError errorWithDomain:@"Bluetooth not powered on." code:1 userInfo:nil]);
        return;
    }
    
    // set the current found dongle reaction
    dongler.scanDongleFoundAction = foundDongle;
    
    // seems like this has to happen on the main thread
    [dongler.centralManager scanForPeripheralsWithServices:services options:nil];
    
    dispatch_async(dongler.scanQueue, ^{
        // wait here until their peripheral scan has completed
        long hasTimedOut = NO;
        while(!hasTimedOut){
            hasTimedOut = dispatch_semaphore_wait(dongler.scanSem, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        }
        
        // no new dongles showed up for 10 seconds. stop scanning.
        dispatch_async(dispatch_get_main_queue(), ^{
            [dongler.centralManager stopScan];
            
            // finish and call the completion handler
            complete(nil);
        });
    });
}

+ (void)connectToDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete
{
    Dongler* dongler = [self sharedDongler];

    [dongler.connectingToDongleLock lock];
    dongler.currentDongle = dongle;
    dongler.connectedToDongleAction = complete;
    [dongler.centralManager connectPeripheral:dongle.peripheral options:nil];
}


+ (void)disconnectFromDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete
{
    Dongler* dongler = [self sharedDongler];
    
    dongler.disconnectedFromDongleAction = complete;
    [dongler.centralManager cancelPeripheralConnection:dongle.peripheral];
}


@end
