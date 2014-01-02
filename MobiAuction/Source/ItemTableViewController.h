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

#import <UIKit/UIKit.h>

#import "EGORefreshTableHeaderView.h"
#import "ItemTableViewCell.h"

@interface ItemTableViewController : UIViewController <EGORefreshTableHeaderDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate> {

}

@property(readwrite, nonatomic, weak) IBOutlet UITableView *tableView;
@property(readwrite, nonatomic, weak) IBOutlet ItemTableViewCell *tableViewCell;
@property(readwrite, nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property(readwrite, nonatomic, strong) IBOutlet UIView *emptyView;
@property(readwrite, nonatomic, strong) IBOutlet UIView *overlayView;

@property(readwrite, nonatomic, assign, getter=isUpdating) BOOL updating;
@property(readwrite, nonatomic, strong) NSDate *lastUpdate;

@property(readonly, nonatomic, strong) id tableViewCellNib;
@property(readonly, nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(readonly, nonatomic, strong) EGORefreshTableHeaderView *tableHeaderView;

@property(readwrite, nonatomic, strong) NSString *searchFilter;
@property(readwrite, nonatomic, strong) NSString *categoryFilter;
@property(readwrite, nonatomic, strong) NSNumber *myItemsFilter;
@property(readwrite, nonatomic, strong) NSNumber *noBidsFilter;

- (void)updateData:(BOOL)force;
- (void)updateView:(BOOL)force;

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active;

@end
