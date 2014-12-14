//
//  EmailAddressBookPickerViewController.h
//  EmailAddressBookPicker
//
//  Created by Eric Mansfield on 12/14/14.
//  Copyright (c) 2014 Eric Mansfield. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmailAddressBookPickerDelegate;

@interface EmailAddressBookPickerViewController : UITableViewController< UIActionSheetDelegate>

@property (nonatomic, weak) id<EmailAddressBookPickerDelegate> delegate;

@end

@protocol EmailAddressBookPickerDelegate <NSObject>

@optional
- (void)addressBookPickerDidCancel:(EmailAddressBookPickerViewController *)controller;

@required
- (void)addressBookPicker:(EmailAddressBookPickerViewController *)controller didFinishWithResults:(NSDictionary *)results;



@end

