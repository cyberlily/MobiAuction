/* Created by Samuel Taylor.
 * Copyright (c) 2012 mobiaware.com.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ApiOperationService.h"
#import "AppConstants.h"
#import "AppDelegate.h"
#import "BidOperation.h"    
#import "DejalActivityView.h"
#import "Item.h"
#import "ItemDetailViewController.h"
#import "ItemImageViewController.h"
#import "Logging.h"
#import "TextStepperField.h"
#import "User.h"
#import "WatchOperation.h"

@interface ItemDetailViewController (PrivateMethods)
- (void)onApiOperationServiceComplete:(NSNotification *)notification;
- (void)updateApiOperationServiceComplete; // update ui on main thread after NSOpertion completion

- (void)onRefreshView:(NSNotification *)notification;

- (void)noDialog:(id)sender;
- (void)yesDialogForBid:(id)sender;
- (void)yesDialogForWatch:(id)sender;
@end

@implementation ItemDetailViewController

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ItemDetailViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"ItemDetailViewController_iPad" bundle:nil];
    }
    
    if (self) {
        // nothing
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlack];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BACK", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
    
    UIView *clearView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    [clearView setBackgroundColor:[UIColor clearColor]];
    [[self tableView] setTableHeaderView:clearView];
    [[self tableView] setTableFooterView:clearView];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Add to My Items" attributes:@{ NSUnderlineStyleAttributeName:@1, NSForegroundColorAttributeName:[UIColor blackColor] }];
        [[self favoriteButton] setAttributedTitle:title forState:UIControlStateNormal];

        NSAttributedString *title2 = [[NSAttributedString alloc] initWithString:@"View photo" attributes:@{ NSUnderlineStyleAttributeName:@1, NSForegroundColorAttributeName:[UIColor blackColor] }];
        [[self imageButton] setAttributedTitle:title2 forState:UIControlStateNormal];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:animated];
    
    [[self nameLabel] setText:@""];
    [[self curPriceLabel] setText:@""];
    [[self favoriteImage] setHidden:YES];
    [[self winningImage] setHidden:YES];
    [[self losingImage] setHidden:YES];
    [[self imageButton] setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onRefreshView:) name:kRefreshView object:nil];

    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kRefreshView object:nil];
}

- (void)updateView:(BOOL)force {
    [self setTitle:[NSString stringWithFormat:NSLocalizedString(@"ITEM_NUMBER", nil), [[self item] itemNumber]]];
    
    double bidValue = [[[self item] curPrice] floatValue] + [[[self item] incPrice] floatValue];
        
    [[self bidPriceField] setCurrent:bidValue];
    [[self bidPriceField] setStep:[[[self item] incPrice] floatValue]];
    [[self bidPriceField] setMinimum:bidValue];
    [[self bidPriceField] setMaximum:kBidValueMax];
    [[self bidPriceField] setNumDecimals:2];
    [[self bidPriceField] setIsEditableTextField:NO];

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];
    
    [[self nameLabel] setText:[[self item] name]];
        
    if ([[[self item] multi] intValue] > 0) {
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"FIXED_PRICE", nil),[numberFormatter stringFromNumber:[[self item] minPrice]]];
        [[self curPriceLabel] setText:msg];
        [[self favoriteButton] setHidden:YES];
        [[self bidPriceField] setEnabled:NO];
    } else {
        [[self curPriceLabel] setText:[numberFormatter stringFromNumber:[[self item] curPrice]]];
        [[self favoriteButton] setHidden:NO];
        [[self bidPriceField] setEnabled:YES];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [[self favoriteImage] setHidden:YES];
        [[self winningImage] setHidden:YES];
        [[self losingImage] setHidden:YES];
        //[[self favoriteButton] setHidden:YES];
    } else {
        [[self favoriteImage] setHidden:![[[self item] hasWatch] boolValue]];
        [[self winningImage] setHidden:![[[self item] isWinning] boolValue]];
        [[self losingImage] setHidden:!(![[[self item] isWinning] boolValue] && [[[self item] hasBid] boolValue])];
        //[[self favoriteButton] setHidden:NO];
    }
    
    if ([[self item] url] != nil && [[[self item] url] length] > 0) {
        [[self imageButton] setHidden:NO];
    }
        
    [[self tableView] reloadData];
}

- (IBAction)bidButtonClicked:(id)sender {
    if (![[self bidButton] isEnabled]) {
        return;
    }
    
    // IMPORTANT! Get the value before displaying the dialog so if we are updated while
    // the dialog is open the price change is not reflected.
    [self setBidValue:[[self bidPriceField] Current]];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];
    
    NSDecimalNumber *floatDecimal = [[NSDecimalNumber alloc] initWithDouble:[self bidValue]];
    NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"PROMPT_BID", nil),[numberFormatter stringFromNumber:floatDecimal], [[self item] itemNumber]];
 
    CODialog *dlg = [CODialog dialogWithWindow:self.view.window];
    [dlg setDialogStyle:CODialogStyleDefault];
    [dlg setTitle:kAppName];
    [dlg setSubtitle:msg];
    [dlg addButtonWithTitle:NSLocalizedString(@"NO", nil) target:self selector:@selector(noDialog:)];
    [dlg addButtonWithTitle:NSLocalizedString(@"YES", nil) target:self selector:@selector(yesDialogForBid:) highlighted:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [dlg addTextFieldWithPlaceholder:NSLocalizedString(@"BIDDER_NUMBER", nil) secure:NO];
        [dlg addTextFieldWithPlaceholder:NSLocalizedString(@"PASSWORD", nil) secure:YES];
    }
    [self setDialog:dlg];
    [[self dialog] showOrUpdateAnimated:YES];
}

- (void)noDialog:(id)sender {
    [[self dialog] hideAnimated:YES];
}

- (void)yesDialogForBid:(id)sender {
    [[self dialog] hideAnimated:YES];
   
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    ApiOperationService *ops = [ApiOperationService instance];
    [ops suspendService]; // start suspended

    BidOperation *op = [[BidOperation alloc] initOperation:context];
    [op setAuctionuid:[appDelegate auctionUid]];
    [op setItemuid:[[self item] uid]];
    [op setBid:[[NSDecimalNumber alloc] initWithDouble:[self bidValue]]];
 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [op setBiddernumber:[[self dialog] textForTextFieldAtIndex:0]];
        [op setPassword:[[self dialog] textForTextFieldAtIndex:1]];
    } else {
        [op setBiddernumber:[[appDelegate user] bidderNumber]];
        [op setPassword:[[appDelegate user] password]];
    }
    
    [ops addOperation:op];
        
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onApiOperationServiceComplete:) name:kApiOperationServiceComplete object:nil];
    
    [ops resumeService]; // go!
    
    DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_BIDDING", nil)];
    [activityView setShowNetworkActivityIndicator:YES];
}

- (IBAction)imageButtonClicked:(id)sender {
    ItemImageViewController *itemImageViewController = [[ItemImageViewController alloc] init];
    [itemImageViewController setItem:[self item]];
    
    [[self navigationController] pushViewController:itemImageViewController animated:YES];
}

- (IBAction)favoriteButtonClicked:(id)sender {
    if (![[self favoriteButton] isEnabled]) {
        return;
    }
    
    NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"PROMPT_WATCH", nil), [[self item] itemNumber]];
 
    CODialog *dlg = [CODialog dialogWithWindow:self.view.window];
    [dlg setDialogStyle:CODialogStyleDefault];
    [dlg setTitle:kAppName];
    [dlg setSubtitle:msg];
    [dlg addButtonWithTitle:NSLocalizedString(@"NO", nil) target:self selector:@selector(noDialog:)];
    [dlg addButtonWithTitle:NSLocalizedString(@"YES", nil) target:self selector:@selector(yesDialogForWatch:) highlighted:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [dlg addTextFieldWithPlaceholder:NSLocalizedString(@"BIDDER_NUMBER", nil) secure:NO];
        [dlg addTextFieldWithPlaceholder:NSLocalizedString(@"PASSWORD", nil) secure:YES];
    }
    [self setDialog:dlg];
    [[self dialog] showOrUpdateAnimated:YES];
}

- (void)yesDialogForWatch:(id)sender {
    [[self dialog] hideAnimated:YES];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    ApiOperationService *ops = [ApiOperationService instance];
    [ops suspendService]; // start suspended

    WatchOperation *op = [[WatchOperation alloc] initOperation:context];
    [op setAuctionuid:[appDelegate auctionUid]];
    [op setItemuid:[[self item] uid]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [op setBiddernumber:[[self dialog] textForTextFieldAtIndex:0]];
        [op setPassword:[[self dialog] textForTextFieldAtIndex:1]];
    } else {
        [op setBiddernumber:[[appDelegate user] bidderNumber]];
        [op setPassword:[[appDelegate user] password]];
    }

    [ops addOperation:op];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onApiOperationServiceComplete:) name:kApiOperationServiceComplete object:nil];
    
    [ops resumeService]; // go!
    
    DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_WATCHING", nil)];
    [activityView setShowNetworkActivityIndicator:YES];
}

- (void)onApiOperationServiceComplete:(NSNotification *)notification {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationServiceComplete object:nil];
    
    [self performSelectorOnMainThread:@selector(updateApiOperationServiceComplete) withObject:nil waitUntilDone:NO];
}

- (void)updateApiOperationServiceComplete {
    [DejalBezelActivityView removeViewAnimated:YES];
    
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)onRefreshView:(NSNotification *)notification {
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[[self item] multi] intValue] > 0) {
        return 3;
    } else {
        return 6;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        [[cell textLabel] setFont:[UIFont systemFontOfSize:14.0]];
        [[cell textLabel] setTextColor:[UIColor blackColor]];
        [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
        [[cell detailTextLabel] setTextColor:[UIColor blackColor]];

        // Fix for iOS 7 to clear backgroundColor
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [UIView new];
        cell.selectedBackgroundView = [UIView new];
    }
   
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];
    
    if ([[[self item] multi] intValue] > 0) {
        if (indexPath.row == 0) {
            [[cell textLabel] setText:NSLocalizedString(@"DONATED_BY", nil)];
            [[cell detailTextLabel] setText:[[self item] seller]];
        } else if (indexPath.row == 1) {
            [[cell textLabel] setText:NSLocalizedString(@"VALUE", nil)];
            [[cell detailTextLabel] setText:[numberFormatter stringFromNumber:[[self item] valPrice]]];
        } else if (indexPath.row == 2) {
            [[cell textLabel] setText:[[self item] desc]];
            [[cell textLabel] setNumberOfLines:15];
            [[cell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
        }
    } else {
        if (indexPath.row == 0) {
            [[cell textLabel] setText:NSLocalizedString(@"MIN_INC", nil)];
            [[cell detailTextLabel] setText:[numberFormatter stringFromNumber:[[self item] incPrice]]];
        } else if (indexPath.row == 1) {
            [[cell textLabel] setText:NSLocalizedString(@"WINNING_BIDDER", nil)];
            if ([[self item] winner] && [[[self item] winner] length] > 0) {
                [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [[self item] winner]]];
            } else {
                [[cell detailTextLabel] setText:NSLocalizedString(@"NO_BIDS", nil)];
            }
        } else if (indexPath.row == 2) {
            [[cell textLabel] setText:NSLocalizedString(@"NUMBER_BIDS", nil)];
            if ([[[self item] bidCount] intValue] > 0) {
                [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [[self item] bidCount]]];
            } else {
                [[cell detailTextLabel] setText:@"0"];
            }
        } else if (indexPath.row == 3) {
            [[cell textLabel] setText:NSLocalizedString(@"DONATED_BY", nil)];
            [[cell detailTextLabel] setText:[[self item] seller]];
        } else if (indexPath.row == 4) {
            [[cell textLabel] setText:NSLocalizedString(@"VALUE", nil)];
            [[cell detailTextLabel] setText:[numberFormatter stringFromNumber:[[self item] valPrice]]];
        } else if (indexPath.row == 5) {
            [[cell textLabel] setText:[[self item] desc]];
            [[cell textLabel] setNumberOfLines:15];
            [[cell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
            [[cell detailTextLabel] setText:nil];
        } 
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    if ([[[self item] multi] intValue] > 0) {
        if (indexPath.row == 2) {
            CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
            CGSize labelSize = [[[self item] desc] sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
            return labelSize.height + 20;
        }
    } else {
        if (indexPath.row == 5) {
            CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
            CGSize labelSize = [[[self item] desc] sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
            return labelSize.height + 20;
        }
    }
    return 44.0;
}

@end
