//
//  Dongler.m
//  Dongler
//
//  Created by Joseph Rivard on 11/18/15.
//  Copyright © 2015 LiftMaster. All rights reserved.
//

#import "Dongler.h"

@implementation Dongler

- (instancetype)init
{
    self = [super init];
    if(!self) return self;
    
    return self;
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

+ (Dongle *)connectedDongle
{
    return nil;
}

+ (void)listDonglesWithCompletion:(DonglerListComplete)complete
{
    
}

+ (void)connectToDongle:(Dongle*)dongle withCompletion:(DonglerConnectionStateComplete)complete
{
    
}


+ (void)disconnectFromDongle:(Dongle*)dongle withCompletion:(DonglerConnectionStateComplete)complete
{
    
}


@end
