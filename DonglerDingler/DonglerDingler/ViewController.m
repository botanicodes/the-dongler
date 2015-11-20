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

@property (strong, nonatomic) IBOutlet UITableView *dongleTable;
@property NSMutableArray<Dongle*>* foundDongles;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dongleTable.delegate = self;
    self.dongleTable.dataSource = self;
    [Dongler prepare];

    _foundDongles = [[NSMutableArray<Dongle*> alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addDongle:(Dongle*)dongle
{
//     [self.dongleTable reloadData];
}

- (IBAction)scan:(id)sender {
    [self.foundDongles removeAllObjects];
    
    NSLog(@"Dongling...");
    [self.spinner startAnimating];
    
    DonglerFoundDongle foundDongle = ^(Dongle* dongle){
        [self.foundDongles addObject:dongle];
        [self.dongleTable reloadData];
    };
    
    DonglerActionComplete doneScanning = ^(NSError* err){
        NSLog(@"Done!");
        [self.spinner setHidden:YES];
        [self.spinner stopAnimating];
    };
    
    [Dongler listDonglesWithServices:@[[CBUUID UUIDWithString:@"FF00"], [CBUUID UUIDWithString:@"FF04"]]
                         foundDongle:foundDongle
                      withCompletion:doneScanning];

}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"dongleCell"]; //[tableView dequeueReusableCellWithIdentifier:@"dongleCell"];
    CBPeripheral* peripheral = self.foundDongles[indexPath.row].peripheral;
    
    NSString* desc = [NSString stringWithFormat:@"%@ %@", (peripheral.state == CBPeripheralStateConnected ? @"Connected!" : @""), [peripheral.identifier UUIDString]];
    
    [cell.textLabel setText:peripheral.name];
    [cell.detailTextLabel setText:desc];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Dongle* dongle = self.foundDongles[indexPath.row];
    
    if(dongle.peripheral.state == CBPeripheralStateConnected){
        [Dongler disconnectFromDongle:dongle withCompletion:^(NSError *error) {
            NSLog(@"Dongle disconnected");
            [self.dongleTable reloadData];
        }];
    }
    else{
        [Dongler connectToDongle:dongle withCompletion:^(NSError *error) {
            if(error){
                NSLog(@"connection failed %@", error.description);
            }
            else{
                NSLog(@"Dongle connected!");
                [self.dongleTable reloadData];
                [self readValueFromDongle: dongle];
            }
        }];
    }

}

- (void) readValueFromDongle:(Dongle *)dongle {
    NSData *data = [dongle readDataFromUUID:[CBUUID UUIDWithString:@"FF01"]];
    NSLog(@"%@", data);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.foundDongles.count;
}

@end
