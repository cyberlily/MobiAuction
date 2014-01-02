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

#import "CODialog.h"
#import "CoolButton.h"
#import "Item.h"
#import "TextStepperField.h"

@interface ItemDetailViewController : UIViewController<UITableViewDelegate> {

}

@property(readwrite, nonatomic, weak) IBOutlet UILabel *nameLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *curPriceLabel;
@property(readwrite, nonatomic, weak) IBOutlet CoolButton *bidButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *imageButton;
@property(readwrite, nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property(readwrite, nonatomic, weak) IBOutlet TextStepperField *bidPriceField;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *favoriteImage;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *winningImage;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *losingImage;
@property(readwrite, nonatomic, weak) IBOutlet UITableView *tableView;

@property(readwrite, nonatomic, strong) Item *item;
@property(readwrite, nonatomic, strong) CODialog *dialog;

@property(readwrite, nonatomic, assign) double bidValue;

- (IBAction)bidButtonClicked:(id)sender;
- (IBAction)imageButtonClicked:(id)sender;
- (IBAction)favoriteButtonClicked:(id)sender;

- (void)updateView:(BOOL)force;

@end
