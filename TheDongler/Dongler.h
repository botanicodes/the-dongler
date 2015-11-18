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

typedef void(^DonglerListComplete)           (NSArray<Dongle*>*, NSError*);
typedef void(^DonglerConnectionStateComplete)(NSError*);

@interface Dongler : NSObject<CBCentralManagerDelegate>

+ (Dongle *)connectedDongle;

+ (void)listDonglesWithCompletion:(DonglerListComplete)complete;
+ (void)connectToDongle:(Dongle*)dongle withCompletion:(DonglerConnectionStateComplete)complete;
+ (void)disconnectFromDongle:(Dongle*)dongle withCompletion:(DonglerConnectionStateComplete)complete;

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
