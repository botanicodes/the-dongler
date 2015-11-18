//
//  Dongle.m
//  Dongler
//
//  Created by Joseph Rivard on 11/18/15.
//  Copyright © 2015 LiftMaster. All rights reserved.
//

#import "Dongle.h"

@interface Dongle()

@property dispatch_semaphore_t writeSemaphore;
@property dispatch_semaphore_t readSemaphore;

@end

@implementation Dongle

+ (Dongle *)withPeripheral:(CBPeripheral *)peripheral {
    Dongle *dongle = [[Dongle alloc] init];
    dongle.peripheral = peripheral;
    peripheral.delegate = dongle;
    
    return dongle;
}

- init {
    self = [super init];
    if(!self)
        return nil;
    
    self.writeSemaphore = dispatch_semaphore_create(0);
    self.readSemaphore = dispatch_semaphore_create(0);
    
    return self;
}


- (void)writeData:(NSData *)data toUUID:(CBUUID *)uuid {
    CBCharacteristic *characteristic = [self getCharacteristicByUuid:uuid];
    
    if(!characteristic)
        return;

    // Write data
    [self.peripheral writeValue:data forCharacteristic:characteristic type:nil];
    
    [self waitForWriteToComplete];
        
}

- (NSData *)readDataFromUUID:(CBUUID *)uuid {
    return nil;
}
     
#pragma mark - Private

- (NSError *) waitForWriteToComplete {
    // wait for did write
    long hasTimedOut = dispatch_semaphore_wait(self.writeSemaphore, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    
    if(hasTimedOut) {
        return [NSError errorWithDomain:@"Timed out when attempting to write" code:100 userInfo:nil];
    }
    
    return nil;
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

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_semaphore_signal(self.writeSemaphore);
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    // watch signal strength
}


@end
