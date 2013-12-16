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

#import "FundACauseViewController.h"

#import "ApiOperationService.h"
#import "AppConstants.h"
#import "AppDelegate.h" 
#import "DejalActivityView.h"
#import "FundACauseOperation.h"
#import "Item.h"
#import "Logging.h"
#import "TextStepperField.h"
#import "User.h"

@interface FundACauseViewController (PrivateMethods)
- (void)promptUser;

- (void)onApiOperationServiceComplete:(NSNotification *)notification;
- (void)updateApiOperationServiceComplete; // update ui on main thread after NSOpertion completion

- (void)onRefreshView:(NSNotification *)notification;

- (void)noDialog:(id)sender;
- (void)yesDialog:(id)sender;
@end

@implementation FundACauseViewController

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"FundACauseViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"FundACauseViewController_iPad" bundle:nil];
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
    
    [self setTitle:NSLocalizedString(@"FUND_A_CAUSE", nil)];
        
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];

    [[self oneButton] setTitle:[numberFormatter stringFromNumber:@(kFundACauseValueOne)] forState:UIControlStateNormal];
    [[self twoButton] setTitle:[numberFormatter stringFromNumber:@(kFundACauseValueTwo)] forState:UIControlStateNormal];
    [[self threeButton] setTitle:[numberFormatter stringFromNumber:@(kFundACauseValueThree)] forState:UIControlStateNormal];
    
    [[self priceField] setCurrent:kFundACauseValueOther];
    [[self priceField] setStep:kFundACauseValueIncrement];
    [[self priceField] setMinimum:kFundACauseValueMin];
    [[self priceField] setMaximum:kFundACauseValueMax];
    [[self priceField] setNumDecimals:2];
    [[self priceField] setIsEditableTextField:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:animated];
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

- (IBAction)oneButtonClicked:(id)sender {
    [self setBid:[[NSDecimalNumber alloc] initWithDouble:kFundACauseValueOne]];
    [self promptUser];
}

- (IBAction)twoButtonClicked:(id)sender {
    [self setBid:[[NSDecimalNumber alloc] initWithDouble:kFundACauseValueTwo]];
    [self promptUser];
}

- (IBAction)threeButtonClicked:(id)sender {
    [self setBid:[[NSDecimalNumber alloc] initWithDouble:kFundACauseValueThree]];
    [self promptUser];
}

- (IBAction)otherButtonClicked:(id)sender{
    [self setBid:[[NSDecimalNumber alloc] initWithDouble:[[self priceField] Current]]];
    [self promptUser];
}

- (void)promptUser {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];
    
    NSString* msg = NSLocalizedString(@"PROMPT_FUNDACAUSE", nil);
 
    [self setDialog:[CODialog dialogWithWindow:self.view.window]];
    [[self dialog] setDialogStyle:CODialogStyleDefault];
    [[self dialog] setTitle:kAppName];
    [[self dialog] setSubtitle:[NSString stringWithFormat:msg, [numberFormatter stringFromNumber:[self bid]]]];
    [[self dialog] addButtonWithTitle:NSLocalizedString(@"NO", nil) target:self selector:@selector(noDialog:)];
    [[self dialog] addButtonWithTitle:NSLocalizedString(@"YES", nil) target:self selector:@selector(yesDialog:) highlighted:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        [[self dialog] addTextFieldWithPlaceholder:NSLocalizedString(@"BIDDER_NUMBER", nil) secure:NO];
        [[self dialog] addTextFieldWithPlaceholder:NSLocalizedString(@"PASSWORD", nil) secure:YES];  
    }

    [[self dialog] showOrUpdateAnimated:YES];
}

- (void)updateView:(BOOL)force {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setGeneratesDecimalNumbers:NO];
    [numberFormatter setMaximumFractionDigits:0];
    [numberFormatter setNotANumberSymbol:@"$0"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDecimalNumber *floatDecimal = [NSDecimalNumber decimalNumberWithString:[defaults stringForKey:@"fundacause"]];
        
    [[self sumLabel] setText:[numberFormatter stringFromNumber:floatDecimal]];
}

- (void)noDialog:(id)sender {
    [[self dialog] hideAnimated:YES];
}

- (void)yesDialog:(id)sender {
    [[self dialog] hideAnimated:YES];

    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    ApiOperationService *ops = [ApiOperationService instance];
    [ops suspendService]; // start suspended

    FundACauseOperation *op = [[FundACauseOperation alloc] initOperation:context];
    [op setAuctionuid:[appDelegate auctionUid]];
    [op setBid:[self bid]];
    
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
    
    DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_FUNDING", nil)];
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

@end
