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

#import "CategoryTableViewController.h"

#import "AppConstants.h"
#import "AppDelegate.h"
#import "Category.h"
#import "CategoryTableViewCell.h"
#import "GetCategoriesOperation.h"
#import "ItemTableViewController.h"
#import "Logging.h"
#import "User.h"

@interface ItemTableViewController (PrivateMethods)
- (void)cancelBarButtonItemClicked:(id)sender;
@end

@implementation CategoryTableViewController

@synthesize tableViewCellNib = _tableViewCellNib;
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"CategoryTableViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"CategoryTableViewController_iPad" bundle:nil];
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
    
    [self performSelector:@selector(updateView:) withObject:NO afterDelay:0.0];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = [[[self fetchedResultsController] sections] count];
    if (sections > 0) {
        return sections;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
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
    static NSString *categoryCellIdentifier = @"CategoryTableViewCellIdentifier";
    
    CategoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:categoryCellIdentifier];
    if (cell == nil) {
        if ([self tableViewCellNib]) {
            [[self tableViewCellNib] instantiateWithOwner:self options:nil];
        } else {
            [[NSBundle mainBundle] loadNibNamed:@"CategoryTableViewCell" owner:self options:nil];
        }
        cell = [self tableViewCell];
        [self setTableViewCell:nil];
    }

    Category *category = (Category *) [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (category != nil) {
        [[cell nameLabel] setText:[category name]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemTableViewController *itemTableViewController = [[ItemTableViewController alloc] init];
    [itemTableViewController setCategoryFilter:nil];
    [itemTableViewController setSearchFilter:nil];
    [itemTableViewController setMyItemsFilter:nil];
    [itemTableViewController setNoBidsFilter:nil];
        
    Category *category = (Category *) [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (category != nil) {
        [itemTableViewController setCategoryFilter:[category name]];
    }
    
    [[self navigationController] pushViewController:itemTableViewController animated:YES];
}

- (id)tableViewCellNib {
    if (_tableViewCellNib) {
        return _tableViewCellNib;
    }
    
    Class cls = NSClassFromString(@"UINib");
    if ([cls respondsToSelector:@selector(nibWithNibName:bundle:)]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _tableViewCellNib = [cls nibWithNibName:@"CategoryTableViewCell_iPhone" bundle:[NSBundle mainBundle]];
        } else {
            _tableViewCellNib = [cls nibWithNibName:@"CategoryTableViewCell_iPad" bundle:[NSBundle mainBundle]];
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

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:30];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];

    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [_fetchedResultsController setDelegate:self];

    fetchRequest = nil;
    sortDescriptor = nil;
    sortDescriptors = nil;

    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        LogError(@"%@", [error localizedDescription]);
    }

    return _fetchedResultsController;
}

- (void)updateView:(BOOL)force {
    if (force) {
        [_fetchedResultsController setDelegate:nil]; // pages should always be updated on new data
        _fetchedResultsController = nil;
    }

    [[self tableView] reloadData];
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
    
    [[self searchBar] setText:@""];
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
		
        // probably not needed if you have a details view since you 
        // will go there on selection
        NSIndexPath *selected = [[self tableView] indexPathForSelectedRow];
        if (selected) {
            [[self tableView] deselectRowAtIndexPath:selected animated:NO];
        }
    }
    [searchBar setShowsCancelButton:active animated:YES];
}

@end
