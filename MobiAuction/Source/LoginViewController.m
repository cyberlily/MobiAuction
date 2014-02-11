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

#import "LoginViewController.h"

#import "ApiOperationService.h"
#import "AppConstants.h"
#import "AppDelegate.h"
#import "ALAlertBanner.h"
#import "DejalActivityView.h"
#import "SignInOperation.h"

static int const kMaximumInputLength = 24;

@interface LoginViewController (PrivateMethods)
- (void)onApiOperationServiceComplete:(NSNotification *)notification;
- (void)updateApiOperationServiceComplete; // update ui on main thread after NSOpertion completion
@end

@implementation LoginViewController

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"LoginViewController_iPhone" bundle:nil];
    } else {
        self = [super initWithNibName:@"LoginViewController_iPad" bundle:nil];
    }
    
    if (self) {
        // nothing
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];

    if ([[self usernameField] isFirstResponder] && [touch view] != [self usernameField]) {
        [[self usernameField] resignFirstResponder];
    }
    else if ([[self passwordField] isFirstResponder] && [touch view] != [self passwordField]) {
        [[self passwordField] resignFirstResponder];
    }

    [super touchesBegan:touches withEvent:event];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (([[textField text] length] >= kMaximumInputLength) && (range.length == 0)) {
        return NO;
    }
    return YES;
}

- (IBAction)textFieldEditingBegin:(id)sender {
    [ALAlertBanner hideAllAlertBanners];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == [self usernameField]) {
        [[self usernameField] becomeFirstResponder];
    } else if (textField == [self passwordField]) {
        if ([[self signInButton] isEnabled]) {
            [[self usernameField] resignFirstResponder];
            [[self passwordField] resignFirstResponder];

            [self signinUsingName:[[self usernameField] text] andPassword:[[self passwordField] text]];
        }
    }
    return YES;
}

- (IBAction)signInButtonClicked:(id)sender {
    if ([[self signInButton] isEnabled]) {
        [[self usernameField] resignFirstResponder];
        [[self passwordField] resignFirstResponder];

        [self signinUsingName:[[self usernameField] text] andPassword:[[self passwordField] text]];
    }
}

- (void)signinUsingName:(NSString *)name andPassword:(NSString *)password {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    ApiOperationService *ops = [ApiOperationService instance];
    [ops suspendService]; // start suspended

    SignInOperation *op = [[SignInOperation alloc] initOperation:context];
    [op setBiddernumber:name];
    [op setPassword:password];

    [ops addOperation:op];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onApiOperationServiceComplete:) name:kApiOperationServiceComplete object:nil];
    
    [ops resumeService]; // go!
    
    DejalActivityView *activityView = [DejalBezelActivityView activityViewForView:[self view] withLabel:NSLocalizedString(@"ACTIVITY_AUTHENTICATING", nil)];
    [activityView setShowNetworkActivityIndicator:YES];
}

- (void)onApiOperationServiceComplete:(NSNotification *)notification {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationServiceComplete object:nil];
    
    [self performSelectorOnMainThread:@selector(updateApiOperationServiceComplete) withObject:nil waitUntilDone:NO];
}

- (void)updateApiOperationServiceComplete {
    [DejalBezelActivityView removeViewAnimated:YES];

    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ([appDelegate user] == nil) {
        ALAlertBanner *banner = [ALAlertBanner alertBannerForView:[appDelegate window]
                                style:ALAlertBannerStyleFailure
                                position:ALAlertBannerPositionTop
                                title:kAppName
                                subtitle:NSLocalizedString(@"ERROR_LOGIN", nil)];

        banner.secondsToShow = 0.0;
        [banner show];
    } else {
        [[appDelegate navigationController] dismissModalViewControllerAnimated:YES];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:kSigninComplete object:self userInfo:nil];
    }
}

@end
