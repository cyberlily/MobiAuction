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
#import "TextStepperField.h"

@interface FundACauseViewController : UIViewController {

}

@property(readwrite, nonatomic, weak) IBOutlet UIImageView *backgroundView;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *sumLabel;
@property(readwrite, nonatomic, weak) IBOutlet CoolButton *oneButton;
@property(readwrite, nonatomic, weak) IBOutlet CoolButton *twoButton;
@property(readwrite, nonatomic, weak) IBOutlet CoolButton *threeButton;
@property(readwrite, nonatomic, weak) IBOutlet CoolButton *otherButton;
@property(readwrite, nonatomic, weak) IBOutlet TextStepperField *priceField;

@property(readwrite, nonatomic, strong) NSDecimalNumber* bid;
@property(readwrite, nonatomic, strong) CODialog *dialog;

- (IBAction)oneButtonClicked:(id)sender;
- (IBAction)twoButtonClicked:(id)sender;
- (IBAction)threeButtonClicked:(id)sender;
- (IBAction)otherButtonClicked:(id)sender;

- (void)updateView:(BOOL)force;

@end
