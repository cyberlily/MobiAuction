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

#import "MainViewController.h"

#import "ApiOperationService.h"
#import "AppConstants.h"
#import "AppDelegate.h"
#import "CategoryTableViewController.h"
#import "CODialog.h"
#import "DejalActivityView.h"
#import "EGORefreshTableHeaderView.h"
#import "FundACauseOperation.h"
#import "FundACauseViewController.h"
#import "GetCategoriesOperation.h"
#import "GetItemsOperation.h"
#import "GetUpdatesOperation.h"
#import "GetMyBidItemsOperation.h"
#import "GetMyWatchItemsOperation.h"
#import "Item.h"
#import "ItemDetailViewController.h"
#import "ItemTableViewController.h"
#import "Logging.h"
#import "LoginViewController.h"
#import "QRCodeReader.h"
#import "User.h"

@interface MainViewController (PrivateMethods)
- (void)onApiOperationServiceComplete:(NSNotification *)notification;
- (void)updateApiOperationServiceComplete; // update ui on main thread after NSOpertion completion

- (void)onRefreshView:(NSNotification *)notification;

- (void)cancelBarButtonItemClicked:(id)sender;
@end

@implementation MainViewController

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"MainViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"MainViewController_iPad" bundle:nil];
    }
    
    if (self) {
        // nothing
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlack];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
        [searchBar setDelegate:self];
        [searchBar setBarStyle:UIBarStyleBlack];
        [searchBar setPlaceholder:NSLocalizedString(@"SEARCH", nil)];

        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            [searchBar sizeToFit];
            [searchBar setBackgroundImage:nil];
        }

        [[self navigationItem] setTitleView:searchBar];
        [self setSearchBar:searchBar];
    }

    NSArray *buttons = @[
                         [self itemsButton],
                         [self categoriesButton],
                         [self scanButton],
                         [self myItemsButton],
                         [self noBidsButton],
                         [self fundACauseButton]];
    for (UIButton *button in buttons) {
        [[button layer] setCornerRadius:8.0f];
        [[button layer] setBorderWidth:1.25f];
        [[button layer] setBorderColor:[UIColor blackColor].CGColor];
        [button setClipsToBounds:YES];
    }
    
    [[self overlayView] removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[self navigationController] setNavigationBarHidden:NO animated:animated];

    [[self searchBar] resignFirstResponder];
    [[self searchBar] setText:nil];
    [[self navigationItem] setRightBarButtonItem:nil animated:YES];
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

- (IBAction)itemsButtonClicked:(id)sender {
    ItemTableViewController *itemTableViewController = [[ItemTableViewController alloc] init];
    [itemTableViewController setCategoryFilter:nil];
    [itemTableViewController setSearchFilter:nil];
    [itemTableViewController setMyItemsFilter:nil];
    [itemTableViewController setNoBidsFilter:nil];
    
    [[self navigationController] pushViewController:itemTableViewController animated:YES];
}

- (IBAction)categoriesButtonClicked:(id)sender {
    UIViewController *categoryTableViewController = [[CategoryTableViewController alloc] init];
    
    [[self navigationController] pushViewController:categoryTableViewController animated:YES];
}

- (IBAction)scanButtonClicked:(id)sender {
    ZXingWidgetController *zxingWidgetController = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];

    QRCodeReader *qrcodeReader = [[QRCodeReader alloc] init];
    NSSet *readers = [[NSSet alloc] initWithObjects:qrcodeReader, nil];
    [zxingWidgetController setReaders:readers];
    [zxingWidgetController setSoundToPlay:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"scan" ofType:@"aiff"] isDirectory:NO]];

    [[zxingWidgetController overlayView] setDisplayedMessage:NSLocalizedString(@"PROMPT_QRCODE", nil)];

    [self presentModalViewController:zxingWidgetController animated:YES];
}

- (IBAction)myItemsButtonClicked:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        [appDelegate showMessage:NSLocalizedString(@"KIOSK_MYITEMS", nil) hideAfter:5.0];
    } else {
        ItemTableViewController *itemTableViewController = [[ItemTableViewController alloc] init];
        [itemTableViewController setCategoryFilter:nil];
        [itemTableViewController setSearchFilter:nil];
        [itemTableViewController setMyItemsFilter:@YES];
        [itemTableViewController setNoBidsFilter:nil];
    
        [[self navigationController] pushViewController:itemTableViewController animated:YES];
    }
}

- (IBAction)noBidsButtonClicked:(id)sender {
    ItemTableViewController *itemTableViewController = [[ItemTableViewController alloc] init];
    [itemTableViewController setCategoryFilter:nil];
    [itemTableViewController setSearchFilter:nil];
    [itemTableViewController setMyItemsFilter:nil];
    [itemTableViewController setNoBidsFilter:@YES];
    
    [[self navigationController] pushViewController:itemTableViewController animated:YES];
}

- (IBAction)fundACauseButtonClicked:(id)sender {
    FundACauseViewController *fundACauseViewController = [[FundACauseViewController alloc] init];
    
    [[self navigationController] pushViewController:fundACauseViewController animated:YES]; 
}

- (void)zxingController:(ZXingWidgetController *)controller didScanResult:(NSString *)result {
    [self dismissModalViewControllerAnimated:NO];

    NSArray *fetchResult = [Item filterByItemNumber:result];
    if ((fetchResult != nil) && ([fetchResult count] > 0)) {
        ItemDetailViewController *itemDetailViewController = [[ItemDetailViewController alloc] init];
        [itemDetailViewController setItem:fetchResult[0]];
        
        [[self navigationController] pushViewController:itemDetailViewController animated:YES];
    } else {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        [appDelegate showMessage:NSLocalizedString(@"ERROR_ITEMNOTFOUND", nil) hideAfter:5.0];
    }
}

- (void)zxingControllerDidCancel:(ZXingWidgetController *)controller {
    [self dismissModalViewControllerAnimated:NO];
}

- (void)updateData:(BOOL)force {
    if (![self isUpdating] || force) {
        [self setUpdating:YES];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];

        ApiOperationService *ops = [ApiOperationService instance];
        [ops suspendService]; // start suspended

        if ([Item hasItems]) {
            GetUpdatesOperation *op = [[GetUpdatesOperation alloc] initOperation:context];
            [op setAuctionuid:[appDelegate auctionUid]];
            [ops addOperation:op];
        } else{
            GetItemsOperation *op = [[GetItemsOperation alloc] initOperation:context];
            [op setAuctionuid:[appDelegate auctionUid]];
            [ops addOperation:op];
        }
        
        GetCategoriesOperation *op2 = [[GetCategoriesOperation alloc] initOperation:context];
        [op2 setAuctionuid:[appDelegate auctionUid]];
        [ops addOperation:op2];
            
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"kiosk"]) {
            // no My Items
        } else {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            User *user = [appDelegate user];
        
            GetMyBidItemsOperation *op3 = [[GetMyBidItemsOperation alloc] initOperation:context];
            [op3 setBiddernumber:[user bidderNumber]];
            [op3 setPassword:[user password]];
            [op3 setAuctionuid:[appDelegate auctionUid]];
            [ops addOperation:op3];
         
            GetMyWatchItemsOperation *op4 = [[GetMyWatchItemsOperation alloc] initOperation:context];
            [op4 setBiddernumber:[user bidderNumber]];
            [op4 setPassword:[user password]];
            [op4 setAuctionuid:[appDelegate auctionUid]];
            [ops addOperation:op4];
        }
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(onApiOperationServiceComplete:) name:kApiOperationServiceComplete object:nil];
        
        [ops resumeService]; // go!
        
        DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_LOADING", nil)];
        [activityView setShowNetworkActivityIndicator:YES];
    }
}

- (void)onApiOperationServiceComplete:(NSNotification *)notification {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationServiceComplete object:nil];
    
    [self performSelectorOnMainThread:@selector(updateApiOperationServiceComplete) withObject:nil waitUntilDone:NO];
}

- (void)updateApiOperationServiceComplete {
    [DejalBezelActivityView removeViewAnimated:YES];
    
    [self setUpdating:NO];
    [self setLastUpdate:[NSDate date]];
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:kRefreshView object:self userInfo:nil];
    //[self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)onRefreshView:(NSNotification *)notification {
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)updateView:(BOOL)force {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [[self bidderNameLabel] setText:NSLocalizedString(@"KIOSK_MODE", nil)];
        [[self bidderNumberLabel] setText:@""];
        [[self winningLabel] setText:@""];
        [[self losingLabel] setText:@""];
    } else {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        User *user = [appDelegate user];
        [[self bidderNameLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"WELCOME", nil), [user firstName]]];
        [[self bidderNumberLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"BIDDER_NUMBER_WITH_VALUE", nil), [user bidderNumber]]];
        [[self winningLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"WINNING", nil), [user winningCount]]];
        [[self losingLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"LOSING", nil), [user losingCount]]];
    }
}

- (void)cancelBarButtonItemClicked:(id)sender {
    [self searchBarCancelButtonClicked:self.searchBar];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonItemClicked:)];
        [self.navigationItem setRightBarButtonItem:cancelBtn animated:YES];
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self searchBar:searchBar activate:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setText:@""];
    [self searchBar:searchBar activate:NO];
    [[self navigationItem] setRightBarButtonItem:nil animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBar:searchBar activate:NO];

   ItemTableViewController *itemTableViewController = [[ItemTableViewController alloc] init];
    [itemTableViewController setCategoryFilter:nil];
    [itemTableViewController setSearchFilter:[searchBar text]];
    [itemTableViewController setMyItemsFilter:nil];
    [itemTableViewController setNoBidsFilter:nil];
    
    [[self navigationController] pushViewController:itemTableViewController animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active{	
    if (!active) {
        [[self overlayView] removeFromSuperview];
        [searchBar resignFirstResponder];
    } else {
        [[self overlayView] setAlpha:0];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            CGFloat y = 0;//self.searchBar.frame.origin.y + self.searchBar.frame.size.height;
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                y = 64;
            }
            [[self overlayView] setFrame:CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.height-y)];
        } else {
            CGFloat y = self.searchBar.frame.origin.y + self.searchBar.frame.size.height ;
            [[self overlayView] setFrame:CGRectMake(4, y, self.view.frame.size.width-8, self.view.frame.size.height-y)];
		}
        [[self view] addSubview:[self overlayView]];

        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        [[self overlayView] setAlpha:0.6];
        [UIView commitAnimations];
    }
    [searchBar setShowsCancelButton:active animated:YES];
}

@end
