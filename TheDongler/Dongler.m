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
@property (weak) DonglerFoundDongle scanDongleFound;

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
    
    return self;
}

#pragma mark - CB delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Dongler status %lu", central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    // invoke the current dongle found block
    [Dongler sharedDongler].scanDongleFound([Dongle withPeripheral:peripheral]);
    
    // tell listDonglesWithSerices: that a new dongle has been found so it doesn't time out yet
    dispatch_semaphore_signal([Dongler sharedDongler].scanSem);
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
    dongler.scanDongleFound = foundDongle;
    
    // seems like this has to happen on the main thread
    [dongler.centralManager scanForPeripheralsWithServices:services options:nil];
    
    dispatch_async(dongler.scanQueue, ^{
        // wait here until their peripheral scan has completed
        long hasTimedOut = NO;
        while(!hasTimedOut){
            hasTimedOut = dispatch_semaphore_wait(dongler.scanSem, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        }
        
        // no new dongles showed up for 10 seconds. stop scanning.
        [dongler.centralManager stopScan];
        
        // finish and call the completion handler
        complete(nil);
    });
}

+ (void)connectToDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete
{

}


+ (void)disconnectFromDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete
{
    
}


@end
