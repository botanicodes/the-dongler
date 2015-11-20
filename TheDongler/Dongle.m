//
//  Dongle.m
//  Dongler
//
//  Created by Joseph Rivard on 11/18/15.
//  Copyright © 2015 LiftMaster. All rights reserved.
//

#import "Dongle.h"

typedef void(^DongleActionComplete)(NSError*);
typedef void(^DongleReadComplete)(NSData*, NSError*);

@interface Dongle()

@property dispatch_semaphore_t writeSemaphore;
@property dispatch_semaphore_t readSemaphore;
@property dispatch_semaphore_t discoverSemaphore;
@property dispatch_queue_t discoveryQueue;

@property NSError *lastError;

@property NSError *lastReadError;
@property NSData *lastReadData;

@end

@implementation Dongle

+ (Dongle *)withPeripheral:(CBPeripheral *)peripheral {
    Dongle *dongle = [[Dongle alloc] initWithPeripheral:peripheral];
    
    return dongle;
}

- (instancetype) initWithPeripheral:(CBPeripheral *) peripheral {
    self = [self init];
    
    _peripheral = peripheral;
    _peripheral.delegate = self;
    
    return self;
}

- (instancetype)init {
    self = [super init];
    if(!self)
        return nil;
    
    _writeSemaphore = dispatch_semaphore_create(0);
    _readSemaphore = dispatch_semaphore_create(0);
    _discoverSemaphore = dispatch_semaphore_create(0);
    
    _discoveryQueue = dispatch_queue_create("dongleServiceDiscoveryQueue", NULL);
    
    return self;
}

- (BOOL) isConnected {
    return self.peripheral.state == CBPeripheralStateConnected;
}

- (void)writeData:(NSData *)data toUUID:(CBUUID *)uuid {
    CBCharacteristic *characteristic = [self getCharacteristicByUuid:uuid];
    __block NSError *error = nil;
    
    // clear last request
    self.lastError = nil;
    
    if(!characteristic)
        return;

    // Get write type
    CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
    if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        writeType = CBCharacteristicWriteWithoutResponse;
    }
    
    // Write data
    [self.peripheral writeValue:data forCharacteristic:characteristic type:writeType];
    
    // wait for write to complete
    [self waitForWriteWithCompletion: ^(NSError *err) {
        error = err;
    }];
}

- (NSData *)readDataFromUUID:(CBUUID *)uuid {
    CBCharacteristic *characteristic = [self getCharacteristicByUuid:uuid];
    __block NSData *data = nil;
    
    self.lastReadData = nil;
    self.lastReadError = nil;
    
    if(!characteristic)
        return nil;
    
    // send command to read value
    [self.peripheral readValueForCharacteristic:characteristic];
    
    // wait for read to complete
    [self waitForReadWithCompletion:^(NSData* d, NSError *error) {
        data = d;
    }];
    
    return data;
}

- (void)interrogate {
    if([self.peripheral.services count])
        return;
    
    dispatch_async(self.discoveryQueue, ^{
        [self.peripheral discoverServices:nil];
    });

    
    dispatch_semaphore_wait(self.discoverSemaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"");
}
     
#pragma mark - Private

- (void) waitForDiscoveryWithCompletion:(DongleActionComplete) completion {
    long hasTimedOut = dispatch_semaphore_wait(self.discoverSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    
    NSError *error = nil;
    if(hasTimedOut) {
        error = [NSError errorWithDomain:@"Timed out when attempting to discover" code:100 userInfo:nil];
    }
    else {
        error = self.lastError;
    }
    completion(error);
}

- (void) waitForWriteWithCompletion: (DongleActionComplete) completion{
    // wait for did write
    long hasTimedOut = dispatch_semaphore_wait(self.writeSemaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    NSError *error = nil;
    if(hasTimedOut) {
        error = [NSError errorWithDomain:@"Timed out when attempting to write" code:100 userInfo:nil];
    }
    else {
        error = self.lastError;
    }
    
    
    completion(error);
}

- (void) waitForReadWithCompletion: (DongleReadComplete) completion{
    NSData *data = nil;
    NSError *error = nil;

    // wait for did read
    long hasTimedOut = dispatch_semaphore_wait(self.readSemaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    if(hasTimedOut) {
        error = [NSError errorWithDomain:@"Timed out when attempting to read" code:100 userInfo:nil];
    }
    else {
        error = self.lastReadError;
        data = self.lastReadData;
    }
    
    
    completion(data, error);
}

 - (CBCharacteristic *) getCharacteristicByUuid:(CBUUID *)uuid {
     for (CBService* service in self.peripheral.services) {
         for (CBCharacteristic* characteristic in service.characteristics) {
             if ([characteristic.UUID isEqual:uuid])
                 return characteristic;
         }
         
     }
     
     return nil;
 }
     
#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if(error) {
        
    }
    long count = [self.peripheral.services count];
    for (int i = 0; i < count; i++) {
        CBService* service = peripheral.services[i];
        
        [peripheral discoverCharacteristics:nil forService:service];
        [peripheral discoverIncludedServices:nil forService:service];
    }
    dispatch_semaphore_signal(self.discoverSemaphore);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    for (int i = 0; i < characteristic.descriptors.count; i++) {
        CBDescriptor* descriptor = characteristic.descriptors[i];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    for (int i = 0; i < service.includedServices.count; i++) {
        CBService* includedService = service.includedServices[i];
        
        [peripheral discoverCharacteristics:nil forService:service];
        [peripheral discoverIncludedServices:nil forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    self.lastReadError = error;
    self.lastReadData = characteristic.value;
    
    dispatch_semaphore_signal(self.readSemaphore);
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    self.lastError = error;
    dispatch_semaphore_signal(self.writeSemaphore);
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    // watch signal strength
}


@end
