//
//  ViewController.m
//  DonglerDingler
//
//  Created by Kirk Roerig on 11/18/15.
//  Copyright © 2015 DongleMaster. All rights reserved.
//

#import "ViewController.h"
#import "TheDongler/Dongler.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [Dongler prepare];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)scan:(id)sender {
    [Dongler listDonglesWithServices:@[[CBUUID UUIDWithString:@"FF00"], [CBUUID UUIDWithString:@"FF04"]]
                         foundDongle:^(Dongle * dongle) {
                             NSLog(@"Dongle found %@", dongle);
                         }
                      withCompletion:^(NSError* error) {
                          NSLog(@"Done!");
                      }];
}

@end
