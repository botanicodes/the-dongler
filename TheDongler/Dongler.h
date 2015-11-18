//
//  Dongler.h
//  Dongler
//
//  Created by Joseph Rivard on 11/18/15.
//  Copyright © 2015 LiftMaster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Dongle.h"

typedef void(^DonglerFoundDongle)(Dongle* dongle);
typedef void(^DonglerActionComplete)(NSError* error);

@interface Dongler : NSObject<CBCentralManagerDelegate>

+ (Dongle *)connectedDongle;

+ (void)prepare;
+ (void)listDonglesWithServices:(NSArray<CBUUID*>*)services
                    foundDongle:(DonglerFoundDongle)foundDongle
                 withCompletion:(DonglerActionComplete)complete;
+ (void)connectToDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete;
+ (void)disconnectFromDongle:(Dongle*)dongle withCompletion:(DonglerActionComplete)complete;

@end

/*
 
    Dongler<CBCentralManagerDelegate>
        + ConnectedDongle
        + List (^{})
        + Connect(^{})
        + Disconnect(^{})
 
        ~
        [Singleton]
 
 
*/
