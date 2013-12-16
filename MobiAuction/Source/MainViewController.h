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
#import <QuartzCore/QuartzCore.h> 

#import "ZXingWidgetController.h"
#import "ItemTableViewController.h"

@interface MainViewController : UIViewController <ZXingDelegate, UISearchBarDelegate> {

}

@property(readwrite, nonatomic, weak) IBOutlet UIButton *itemsButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *categoriesButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *scanButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *myItemsButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *noBidsButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *fundACauseButton;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *bidderNameLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *bidderNumberLabel;
@property(readwrite, nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *winningLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *losingLabel;

@property(readwrite, nonatomic, strong) IBOutlet UIView *overlayView;

@property(readwrite, nonatomic, assign, getter=isUpdating) BOOL updating;
@property(readwrite, nonatomic, strong) NSDate *lastUpdate;

- (IBAction)itemsButtonClicked:(id)sender;
- (IBAction)categoriesButtonClicked:(id)sender;
- (IBAction)scanButtonClicked:(id)sender;
- (IBAction)myItemsButtonClicked:(id)sender;
- (IBAction)noBidsButtonClicked:(id)sender;
- (IBAction)fundACauseButtonClicked:(id)sender;

- (void)updateData:(BOOL)force;
- (void)updateView:(BOOL)force;

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active;

@end
