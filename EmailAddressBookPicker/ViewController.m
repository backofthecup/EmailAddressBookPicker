//
//  ViewController.m
//  EmailAddressBookPicker
//
//  Created by Eric Mansfield on 12/14/14.
//  Copyright (c) 2014 Eric Mansfield. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [segue.destinationViewController setValue:self forKey:@"delegate"];
}

#pragma mark AddressBookPickerDelegate
- (void)addressBookPicker:(EmailAddressBookPickerViewController *)controller didFinishWithResults:(NSDictionary *)results {
    
    [[[UIAlertView alloc] initWithTitle:@"You selected" message:results.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

@end
