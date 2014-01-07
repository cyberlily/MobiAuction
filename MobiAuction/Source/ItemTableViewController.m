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

#import "ItemTableViewController.h"

#import "ApiOperationService.h"
#import "AppConstants.h"
#import "AppDelegate.h"
//#import "DejalActivityView.h"
#import "GetMyBidItemsOperation.h"
#import "GetMyWatchItemsOperation.h"
#import "EGORefreshTableHeaderView.h"
#import "GetItemsOperation.h"
#import "GetUpdatesOperation.h"
#import "Item.h"
#import "ItemDetailViewController.h"
#import "ItemTableViewCell.h"
#import "Logging.h"
#import "User.h"

@interface ItemTableViewController (PrivateMethods)
- (void)onApiOperationServiceComplete:(NSNotification *)notification;
- (void)updateApiOperationServiceComplete; // update ui on main thread after NSOpertion completion

- (void)onRefreshView:(NSNotification *)notification;

- (void)cancelBarButtonItemClicked:(id)sender;
@end

@implementation ItemTableViewController

@synthesize tableHeaderView = _tableHeaderView;
@synthesize tableViewCellNib = _tableViewCellNib;
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ItemTableViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"ItemTableViewController_iPad" bundle:nil];
    }
    
    if (self) {
        [self setLastUpdate:[NSDate date]];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlack];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BACK", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];

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

    [[self tableView] addSubview:[self tableHeaderView]];

    [[self overlayView] removeFromSuperview];
}

- (void)viewDidUnload {
    _tableViewCellNib = nil;
    [_fetchedResultsController setDelegate:nil];
    _fetchedResultsController = nil;

    [super viewDidUnload];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = [[[self fetchedResultsController] sections] count];
    if (sections > 0) {
        return sections;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return 90.0f;
    } else {
        return 228.0f;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger cnt = 0;

    NSInteger sections = [[[self fetchedResultsController] sections] count];
    if (sections > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][section];
        cnt = [sectionInfo numberOfObjects];
    }

    if (cnt == 0) {
        const CGRect rect = (CGRect) {CGPointZero, [self tableView].frame.size};
        [[self emptyView] setFrame:rect];
        [[self view] addSubview:[self emptyView]];
        
        [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [[self emptyView] removeFromSuperview];
        
        [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }

    return cnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *itemCellIdentifier = @"ItemTableViewCellIdentifier";

    ItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    if (cell == nil) {
        if ([self tableViewCellNib]) {
            [[self tableViewCellNib] instantiateWithOwner:self options:nil];
        } else {
            [[NSBundle mainBundle] loadNibNamed:@"ItemTableViewCell" owner:self options:nil];
        }
        cell = [self tableViewCell];
        [self setTableViewCell:nil];
    }

    Item *item = (Item *) [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (item != nil) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [numberFormatter setGeneratesDecimalNumbers:NO];
        [numberFormatter setMaximumFractionDigits:0];
    
        [[cell nameLabel] setText:[item name]];
        [[cell itemLabel] setText:[item itemNumber]];
        [[cell valPriceLabel] setText:[numberFormatter stringFromNumber:[item valPrice]]];
        [[cell curPriceLabel] setText:[numberFormatter stringFromNumber:[item curPrice]]];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // not showing description on iPhone
        } else {
            [[cell descLabel] setText:[item desc]];
        }

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"kiosk"]) {
            [[cell favoriteImage] setHidden:YES];
            [[cell winningImage] setHidden:YES];
            [[cell losingImage] setHidden:YES];
        } else {
            [[cell favoriteImage] setHidden:![[item hasWatch] boolValue]];
            [[cell winningImage] setHidden:![[item isWinning] boolValue]];
            [[cell losingImage] setHidden:!(![[item isWinning] boolValue] && [[item hasBid] boolValue])];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemDetailViewController *itemDetailViewController = [[ItemDetailViewController alloc] init];
 
    Item *item = (Item *) [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (item != nil) {
        [itemDetailViewController setItem:item];
    }   
    
    [[self navigationController] pushViewController:itemDetailViewController animated:YES];
}

- (id)tableViewCellNib {
    if (_tableViewCellNib) {
        return _tableViewCellNib;
    }
    
    Class cls = NSClassFromString(@"UINib");
    if ([cls respondsToSelector:@selector(nibWithNibName:bundle:)]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _tableViewCellNib = [cls nibWithNibName:@"ItemTableViewCell_iPhone" bundle:[NSBundle mainBundle]];
        } else {
            _tableViewCellNib = [cls nibWithNibName:@"ItemTableViewCell_iPad" bundle:[NSBundle mainBundle]];
        }
    }
    
    return _tableViewCellNib;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:30];

    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];    
    NSMutableArray *andPredicates = [[NSMutableArray alloc] init];
    
    if ([[self searchFilter] length] > 0) {
        NSMutableArray *orPredicates = [[NSMutableArray alloc] init];

        [orPredicates addObject:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [self searchFilter]]]; // contains match on name
        
        [orPredicates addObject:[NSPredicate predicateWithFormat:@"itemNumber contains[cd] %@", [self searchFilter]]]; // item number match on name

        [orPredicates addObject:[NSPredicate predicateWithFormat:@"seller contains[cd] %@", [self searchFilter]]]; // contains match on name
        
        NSString *regex = [NSString stringWithFormat:@".*\\b%@\\b.*", [self searchFilter]];
        [orPredicates addObject:[NSPredicate predicateWithFormat:@"desc matches %@", regex]]; // exact match in description

        [andPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:orPredicates]];

        orPredicates = nil;
    }
    
    if ([[self categoryFilter] length] > 0) {
        NSMutableArray *orPredicates = [[NSMutableArray alloc] init];

        [orPredicates addObject:[NSPredicate predicateWithFormat:@"category contains[cd] %@", [self categoryFilter]]]; // contains match on name
 
        [andPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:orPredicates]];

        orPredicates = nil;
    }

    if ([[self myItemsFilter] intValue] != 0) {
        NSSortDescriptor *watchDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hasBid" ascending:NO];
        [sortDescriptors addObject:watchDescriptor];
        watchDescriptor = nil;
        
        NSSortDescriptor *winnerDescriptor = [[NSSortDescriptor alloc] initWithKey:@"isWinning" ascending:YES];
        [sortDescriptors addObject:winnerDescriptor];
        winnerDescriptor = nil;

        NSSortDescriptor *itemNumberDescriptor = [[NSSortDescriptor alloc] initWithKey:@"itemNumber" ascending:YES];
        [sortDescriptors addObject:itemNumberDescriptor];
        itemNumberDescriptor = nil;

        NSMutableArray *orPredicates = [[NSMutableArray alloc] init];
        
        {
            NSExpression *lhs = [NSExpression expressionForKeyPath:@"winner"];
            NSExpression *rhs = [NSExpression expressionForConstantValue:[[appDelegate user] bidderNumber]];
            NSPredicate *winnerequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
                rightExpression:rhs
                modifier:NSDirectPredicateModifier
                type:NSEqualToPredicateOperatorType
                options:NSCaseInsensitivePredicateOption| NSDiacriticInsensitivePredicateOption];
            [orPredicates addObject:winnerequals];
        }
        {
            NSExpression *lhs = [NSExpression expressionForKeyPath:@"hasBid"];
            NSExpression *rhs = [NSExpression expressionForConstantValue:@1];
            NSPredicate *hasbidequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
                rightExpression:rhs
                modifier:NSDirectPredicateModifier
                type:NSEqualToPredicateOperatorType
                options:0];
            [orPredicates addObject:hasbidequals];
        }
        {
            NSExpression *lhs = [NSExpression expressionForKeyPath:@"hasWatch"];
            NSExpression *rhs = [NSExpression expressionForConstantValue:@1];
            NSPredicate *haswatchequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
                rightExpression:rhs
                modifier:NSDirectPredicateModifier
                type:NSEqualToPredicateOperatorType
                options:0];
            [orPredicates addObject:haswatchequals];
        }     

        [andPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:orPredicates]];

        orPredicates = nil;
    }
    
     if ([[self noBidsFilter] intValue] != 0) {
        NSMutableArray *orPredicates = [[NSMutableArray alloc] init];

        [orPredicates addObject:[NSPredicate predicateWithFormat:@"bidCount <=  %@", @1]]; // contains match on bid count
 
        [andPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:orPredicates]];

        orPredicates = nil;
    }
    
    if ([andPredicates count] > 0) {
        [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:andPredicates]];
    }

    if ([sortDescriptors count] == 0) {
        NSSortDescriptor *itemNumberDescriptor = [[NSSortDescriptor alloc] initWithKey:@"itemNumber" ascending:YES];
        [sortDescriptors addObject:itemNumberDescriptor];
        itemNumberDescriptor = nil;
    }
    
    if ([sortDescriptors count] > 0) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
 
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [_fetchedResultsController setDelegate:self];

    andPredicates = nil;
    sortDescriptors = nil;
    fetchRequest = nil;

    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        LogError(@"%@", [error localizedDescription]);
    }

    return _fetchedResultsController;
}

- (EGORefreshTableHeaderView *)tableHeaderView {
    if (_tableHeaderView) {
        return _tableHeaderView;
    }
    
    int width = self.tableView.bounds.size.width;
    int height = self.tableView.bounds.size.height-1;
    
    _tableHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - height, width, height) arrowImageName:@"whiteArrow" textColor:[UIColor blackColor]];
	[_tableHeaderView setDelegate:self];
    [_tableHeaderView setBackgroundColor:[UIColor clearColor]];
    [_tableHeaderView refreshLastUpdatedDate];
    
    return _tableHeaderView;
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
                
            GetMyWatchItemsOperation *op4 = [[GetMyWatchItemsOperation alloc] initOperation:context];
            [op4 setBiddernumber:[user bidderNumber]];
            [op4 setPassword:[user password]];
            [op4 setAuctionuid:[appDelegate auctionUid]];
                
            [ops addOperation:op3];
            [ops addOperation:op4];
        }
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(onApiOperationServiceComplete:) name:kApiOperationServiceComplete object:nil];
        
        [ops resumeService]; // go!
        
        //DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_LOADING", nil)];
        //[activityView setShowNetworkActivityIndicator:YES];
    }
}

- (void)updateView:(BOOL)force {
    if (force) {
        [_fetchedResultsController setDelegate:nil]; // pages should always be updated on new data
        _fetchedResultsController = nil;
    }

    [[self tableView] reloadData];
}

- (void)onApiOperationServiceComplete:(NSNotification *)notification {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationServiceComplete object:nil];
    
    [self performSelectorOnMainThread:@selector(updateApiOperationServiceComplete) withObject:nil waitUntilDone:NO];
}

- (void)updateApiOperationServiceComplete {
    //[DejalBezelActivityView removeViewAnimated:YES];

    [self setUpdating:NO];
    [self setLastUpdate:[NSDate date]];
    
    [[self tableHeaderView] egoRefreshScrollViewDataSourceDidFinishedLoading:[self tableView]];
    
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)onRefreshView:(NSNotification *)notification {
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	[[self tableHeaderView] egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[[self tableHeaderView] egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    [self performSelector:@selector(updateData:) withObject:@YES afterDelay:0.0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return [self isUpdating];
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [self lastUpdate];
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

    [self setCategoryFilter:nil];
    [self setSearchFilter:nil];
    [self setMyItemsFilter:nil];
    [self setNoBidsFilter:nil];
    
    [self performSelector:@selector(updateView:) withObject:@NO afterDelay:0.0];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBar:searchBar activate:NO];

    [self setCategoryFilter:nil];
    [self setSearchFilter:[searchBar text]];
    [self setMyItemsFilter:nil];
    [self setNoBidsFilter:nil];
    
    [self updateView:YES];
}

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active{	
    [[self tableView] setAllowsSelection:!active];
    [[self tableView] setScrollEnabled:!active];

    if (!active) {
        [[self overlayView] removeFromSuperview];
        [searchBar resignFirstResponder];
    } else {
        [[self overlayView] setAlpha:0];

        CGFloat y = 0;//self.searchBar.frame.origin.y + self.searchBar.frame.size.height;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            y = 64;
        }
        [[self overlayView] setFrame:CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.height-y)];

        [[self view] addSubview:[self overlayView]];

        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        [[self overlayView] setAlpha:0.6];
        [UIView commitAnimations];
    }
    [searchBar setShowsCancelButton:active animated:YES];
}

@end
