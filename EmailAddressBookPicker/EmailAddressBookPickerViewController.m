//
//  EmailAddressBookPickerViewController.m
//  EmailAddressBookPicker
//
//  Created by Eric Mansfield on 12/14/14.
//  Copyright (c) 2014 Eric Mansfield. All rights reserved.
//

#import "EmailAddressBookPickerViewController.h"

#import <AddressBook/AddressBook.h>

@interface EmailAddressBookPickerViewController ()

@property (strong, nonatomic) NSArray *contacts;
@property (strong, nonatomic) NSArray *searchResults;

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;
- (void)loadContactsWithEmail;

@end

@implementation EmailAddressBookPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // get permission to use address book
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self loadContactsWithEmail];
            }];
        }
        else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [[[UIAlertView alloc] initWithTitle:@"" message:@"You must grant permission to Contacts in Settings > Privacy > Contacts" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                
            }];
        }
    });
    
    if (addressBook) {
        CFRelease(addressBook);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        rows = _searchResults.count;
    }
    else  {
        rows = _contacts.count;
    }
    
    NSLog(@"Table view rows %@", @(rows));
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    ABRecordRef person = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        person = CFBridgingRetain(_searchResults[indexPath.row]);
    }
    else  {
        person = CFBridgingRetain(_contacts[indexPath.row]);
    }
    
    // reload the person record to get the image
    ABRecordID recordId = ABRecordGetRecordID(person);
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABRecordRef copy = ABAddressBookGetPersonWithRecordID(addressBook, recordId);
    NSData  *imgData = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(copy, kABPersonImageFormatThumbnail));
    
    UIImageView *imageView = cell.imageView;
    if (imgData) {
        UIImage *image = [UIImage imageWithData:imgData];
        imageView.image = image;
    }
    else {
        UIImage *image = [UIImage imageNamed:@"contact"];
        imageView.image = image;
    }
    
    // get the name and number selected
    NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
    NSString *company = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
    
    NSString *name = @"";
    if (first) {
        name = [NSString stringWithFormat:@"%@ ", first];
    }
    if (last) {
        name = [NSString stringWithFormat:@"%@%@", name, last];
    }
    
    // display comany name if no first or last
    if (name.length < 1) {
        name = company;
    }
    
    // display email if nothing else
    if (name.length < 1) {
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        if (emails) {
            name = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emails, 0);
            CFRelease(emails);
        }
    }
    cell.textLabel.text = name;
    
    // display email address in cell subtitle
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 1) {
        cell.detailTextLabel.text = @"Multiple emails";
    }
    else {
        NSString *email = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emails, 0);
        cell.detailTextLabel.text = email;
        
    }
    CFRelease(emails);
    
    
    CFRelease(person);
    CFRelease(addressBook);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ABRecordRef person = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        person = CFBridgingRetain(_searchResults[indexPath.row]);
    }
    else  {
        person = CFBridgingRetain(_contacts[indexPath.row]);
    }
    
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 1) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
        for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++) {
            NSString *email = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emails, i);
            
            [sheet addButtonWithTitle:email];
        }
        
        [sheet showFromTabBar:self.tabBarController.tabBar];
    }
    else {
        if (self.delegate) {
            NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
            NSString *email = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, 0));
            
            NSMutableDictionary *results = [NSMutableDictionary dictionary];
            if (first) {
                results[@"firstName"] = first;
            }
            if (last) {
                results[@"lastName"] = last;
            }
            results[@"emailAddress"] = email;
            
            [self.delegate addressBookPicker:self didFinishWithResults:results];
            
        }
    }
    
    CFRelease(person);
    CFRelease(emails);
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Private Methods
- (void)loadContactsWithEmail {
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                               kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people
                                                               );
    
    
    // sort by first name
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      kABPersonSortByFirstName);
    
    NSMutableArray *array = (NSMutableArray *)CFBridgingRelease(peopleMutable);
    
    
    // Build a predicate that searches for contacts with at least one email
    NSPredicate* predicate = [NSPredicate predicateWithBlock: ^(id record, NSDictionary* bindings) {
        ABRecordRef person = (ABRecordRef)CFBridgingRetain(record);
        
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        BOOL result = NO;
        
        if (ABMultiValueGetCount(emails) > 0) {
            result = YES;
        }
        
        CFRelease(emails);
        CFRelease(person);
        return result;
    }];
    
    // filter contacts with at least one email address
    _contacts = [array filteredArrayUsingPredicate:predicate];
    
    
    [self.tableView reloadData];
    
    CFRelease(people);
    CFRelease(addressBook);
    
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString *)scope
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id record, NSDictionary *bindings) {
        
        ABRecordRef person = (ABRecordRef)CFBridgingRetain(record);
        BOOL result = NO;
        
        NSString *stringToSearch = @"";
        NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        NSString *company = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
        
        if (first) {
            stringToSearch = first;
        }
        if (last) {
            stringToSearch = [NSString stringWithFormat:@"%@ %@", stringToSearch, last];
        }
        if (company) {
            stringToSearch = [NSString stringWithFormat:@"%@ %@", stringToSearch, company];
        }
        
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        if (ABMultiValueGetCount(emails) > 0) {
            for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++) {
                NSString *email = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emails, i);
                
                stringToSearch = [NSString stringWithFormat:@"%@ %@", stringToSearch, email];
            }
        }
        
        NSRange range = [stringToSearch rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            result = YES;
        }
        
        CFRelease(person);
        CFRelease(emails);
        
        return result;
    }];
    
    self.searchResults = [_contacts filteredArrayUsingPredicate:predicate];
    
}

#pragma mark - UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self filterContentForSearchText:searchString scope:[self.searchDisplayController.searchBar scopeButtonTitles][[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    return YES;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSLog(@"Button index.......%@", @(buttonIndex));
        if (self.delegate) {
            NSIndexPath *indexPath = nil;
            ABRecordRef person = nil;
            
            if (self.searchDisplayController.isActive) {
                indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
                person = CFBridgingRetain(_searchResults[indexPath.row]);
            }
            else {
                indexPath = [self.tableView indexPathForSelectedRow];
                person = CFBridgingRetain(_contacts[indexPath.row]);
            }
            
            ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
            NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
            NSString *email = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, buttonIndex - 1));
            
            NSMutableDictionary *results = [NSMutableDictionary dictionary];
            if (first) {
                results[@"firstName"] = first;
            }
            if (last) {
                results[@"lastName"] = last;
            }
            results[@"emailAddress"] = email;
            
            
            [self.delegate addressBookPicker:self didFinishWithResults:results];
            
            CFRelease(person);
            CFRelease(emails);
        }
    }
}

@end
