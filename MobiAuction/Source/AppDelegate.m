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

#import "AppDelegate.h"

#import "ApiOperation.h"
#import "ApiOperationService.h"
#import "AppConstants.h"
#import "HttpConstants.h"
#import "Logging.h"
#import "LoginViewController.h"
#import "MainViewController.h"
#import "NSManagedObjectContext+EntityUpdate.h"
#import "RegisterDeviceOperation.h"
#import "SignInOperation.h"
#import "User.h"
#import "ALAlertBanner.h"
#import "Reachability.h"

double const kSecondsToShow = 10.0;
double const kShowAnimationDuration = 0.25;
double const kHideAnimationDuration = 0.2;

@interface AppDelegate (PrivateMethods)
- (void)setVersion;

- (void)onWebSocketItemUpdateMessage:(NSDictionary *)event;
- (void)onWebSocketFundUpdateMessage:(NSDictionary *)event;

- (void)onSigninComplete:(NSNotification *)notification;

- (void)onApiOperationMessage:(NSNotification *)notification;
- (void)updateApiOperationMessage:(NSString*)message; // update ui on main thread after NSOpertion completion

- (void)reachabilityChanged:(NSNotification *)notification;

#if TARGET_OS_IPHONE
- (void)appDidEnterBackground:(NSNotification *)notificaiton;
- (void)appDidBecomeActive:(NSNotification *)notification;
#endif

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize user = _user;

@synthesize webSocketClient = _webSocketClient;
@synthesize automaticallyReconnect = _automaticallyReconnect;
@synthesize hostReachability = _hostReachability;

#if TARGET_OS_IPHONE
@synthesize automaticallyDisconnectInBackground = _automaticallyDisconnectInBackground;

BOOL _appIsBackgrounded;
#endif

- (void)dealloc {
	[[self hostReachability] stopNotifier];

	[self setAutomaticallyReconnect:NO];
	[self setAutomaticallyDisconnectInBackground:NO];

	[self webSocketDisconnect];

    AudioServicesDisposeSystemSoundID(_notificationSound);

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationMessage object:nil];
    [dnc removeObserver:self name:kSigninComplete object:nil];
	[dnc removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];

    MainViewController *mainViewController = [[MainViewController alloc] init];
    [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:mainViewController]];
    [[self window] setRootViewController:[self navigationController]];
    [[self window] makeKeyAndVisible];

    [[[self navigationController] navigationBar] setTintColor:[UIColor whiteColor]];

    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"message" ofType:@"aiff"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_notificationSound);

    // changes the color of all navigation bars on iOS 6 and lower
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    }

    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlack];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onApiOperationMessage:) name:kApiOperationMessage object:nil];
    [dnc addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceId = [[[deviceToken description]
                           stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                          stringByReplacingOccurrencesOfString:@" "
                          withString:@""];

    NSManagedObjectContext *context = [self managedObjectContext];

    ApiOperationService *ops = [ApiOperationService instance];
    [ops suspendService]; // start suspended

    RegisterDeviceOperation *op = [[RegisterDeviceOperation alloc] initOperation:context];
    [op setUseruid:[[self user] uid]];
    [op setDeviceid:deviceId];
    [op setDevicetype:[[UIDevice currentDevice] model]];

    [ops addOperation:op];

    [ops resumeService]; // go!
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:[appDelegate window]
                                                        style:ALAlertBannerStyleFailure
                                                        position:ALAlertBannerPositionUnderNavBar
                                                        title:kAppName
                                                        subtitle:NSLocalizedString(@"WARNING_REGISTRATION", nil)];
    banner.secondsToShow = 5.0;
    [banner show];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self updateApiOperationMessage:userInfo[@"aps"][@"alert"]];

    AudioServicesPlaySystemSound([self notificationSound]);

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:kRefreshView object:self userInfo:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(onSigninComplete:) name:kSigninComplete object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"reset"]) {
        [self reset];

        [[self navigationController] popToRootViewControllerAnimated:YES];
    }

    if ([defaults boolForKey:@"kiosk"]) {
        [dnc postNotificationName:kSigninComplete object:self userInfo:nil];
    } else {
        if ([self user] == nil) {
            LoginViewController *loginViewController = [[LoginViewController alloc] init];
            [[self navigationController] presentModalViewController:loginViewController animated:NO];
        } else {
            [dnc postNotificationName:kSigninComplete object:self userInfo:nil];
        }
    }

    [dnc postNotificationName:kRefreshView object:self userInfo:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            LogError(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        [_managedObjectContext setUndoManager:nil];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"iOSAuction" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"iOSAuction.sqlite"];

    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Handle error
    }

    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (User *)user {
    if (_user != nil) {
        return _user;
    }

    NSManagedObjectContext *context = [self managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:1]; // only 1

    NSArray *fetchResult = [context executeFetchRequest:fetchRequest error:nil];
    if ((fetchResult != nil) && ([fetchResult count] > 0)) {
        _user = (User *) fetchResult[0];
    }

    fetchRequest = nil;

    return _user;
}

- (NSNumber *)auctionUid {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"kiosk"]) {
        return @1;
    }
    return [[self user] auctionUid];
}

- (void)reset {
    NSManagedObjectContext *context = [self managedObjectContext];

    {
        if (_user != nil) {
            [context deleteObject:_user];
            _user = nil;
        }
    }

    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];

        NSArray * fetchResult = [context executeFetchRequest:fetchRequest error:nil];
        if ((fetchResult != nil) && ([fetchResult count] > 0)) {
            for (id basket in fetchResult) {
                [context deleteObject:basket];
            }
        }

        fetchRequest = nil;
    }

    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];

        NSArray * fetchResult = [context executeFetchRequest:fetchRequest error:nil];
        if ((fetchResult != nil) && ([fetchResult count] > 0)) {
            for (id basket in fetchResult) {
                [context deleteObject:basket];
            }
        }

        fetchRequest = nil;
    }

    [context save:nil];

    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:@"fundacause"];
        [defaults setObject:nil forKey:@"reset"];
        [defaults synchronize];
    }
}

- (void)onWebSocketItemUpdateMessage:(NSDictionary *)event {
    NSMutableDictionary *itemsDict = [NSMutableDictionary dictionary];
    NSDictionary *itemDict = [event valueForKey:@"item"];
    [itemsDict setValue:itemDict forKey:itemDict[@"uid"]];

    NSError *error = nil;
    NSManagedObjectContext *context = [self managedObjectContext];
    [context updateEntity:@"Item"
            forEntityType:nil
           fromDictionary:itemsDict
           withIdentifier:@"uid"
              overwriting:@[@"curPrice", @"bidCount", @"watchCount", @"winner"]
                 removing:NO
                 andError:&error];

    if ([context hasChanges] && ![context save:&error]) {
        LogError(@"%@", [error localizedDescription]);
    }

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:kRefreshView object:self userInfo:nil];
}

- (void)onWebSocketFundUpdateMessage:(NSDictionary *)event {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[event valueForKey:@"sum"] forKey:@"fundacause"];
    [defaults synchronize];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:kRefreshView object:self userInfo:nil];
}

- (void)onSigninComplete:(NSNotification *)notification {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kSigninComplete object:nil];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];

    [self setVersion];

    MainViewController *mainViewController = (MainViewController *)[[[self navigationController] viewControllers] objectAtIndex:0];
    [mainViewController performSelector:@selector(updateData:) withObject:@NO afterDelay:0.0];

    _automaticallyReconnect = YES;

#if TARGET_OS_IPHONE
    _appIsBackgrounded = NO;
    _automaticallyDisconnectInBackground = YES;

    [dnc addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [dnc addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif

    _hostReachability = [Reachability reachabilityForInternetConnection];
    [[self hostReachability] startNotifier];

    [self webSocketConnect];
}

- (void)setVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    [defaults setObject:version forKey:@"version"];
}

- (void)onApiOperationMessage:(NSNotification *)notification {
    [self performSelectorOnMainThread:@selector(updateApiOperationMessage:) withObject:[notification object] waitUntilDone:NO];
}

- (void)updateApiOperationMessage:(NSString*)message {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:[appDelegate window]
                                                        style:ALAlertBannerStyleWarning
                                                        position:ALAlertBannerPositionUnderNavBar
                                                        title:kAppName
                                                        subtitle:message];
    banner.secondsToShow = 5.0;
    [banner show];
}

- (void)setWebSocket:(SRWebSocket *)webSocket {
	if (_webSocketClient) {
		_webSocketClient.delegate = nil;
		[_webSocketClient close];
	}

	_webSocketClient = webSocket;
	_webSocketClient.delegate = self;
}

#if TARGET_OS_IPHONE
- (void)appDidEnterBackground:(NSNotification *)notificaiton {
	_appIsBackgrounded = YES;

	if ([self automaticallyDisconnectInBackground]) {
		[self webSocketDisconnect];
	}
}

- (void)appDidBecomeActive:(NSNotification *)notification {
	if (!_appIsBackgrounded) {
		return;
	}

	_appIsBackgrounded = NO;

	if ([self automaticallyDisconnectInBackground]) {
		[self webSocketConnect];
	}
}
#endif

- (void)reachabilityChanged:(NSNotification *)notification {
#if TARGET_OS_IPHONE
	if (_appIsBackgrounded) {
		return; // if the app is in the background, ignore the notificaiton
	}
#endif

    if ([[self hostReachability] isReachable]) {
		[self webSocketConnect];
	} else {
		[self webSocketDisconnect];
	}
}


- (void)webSocketConnect {
	if ([self isWebSocketConnected]) {
		return;
	}

    [self setWebSocket:[[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kWebSocketUrl]]]];
    [[self webSocketClient] setDelegate:self];
    [[self webSocketClient] open];
}

- (void)webSocketDisconnect {
	if (![self isWebSocketConnected]) {
		return;
	}

    [self setWebSocket:nil];

	if (!_automaticallyReconnect) {
		return;
	}

	if ([[self hostReachability] isReachable]) {
#if TARGET_OS_IPHONE
		if (_appIsBackgrounded && _automaticallyDisconnectInBackground) {
			return;
		}
#endif
		[self webSocketConnect];
	}
}

- (BOOL)isWebSocketConnected {
	return ([self webSocketClient] != nil);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    LogDebug(@"webSocket:didReceiveMessage: %@", message);

    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

    NSMutableDictionary *fundDict = [[jsonDict valueForKey:@"liveauction-fund"] mutableCopy];
    if (fundDict) {
        [self onWebSocketFundUpdateMessage:fundDict];
    }

    NSMutableDictionary *itemDict = [[jsonDict valueForKey:@"liveauction-item"] mutableCopy];
    if (itemDict) {
        [self onWebSocketItemUpdateMessage:itemDict];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    LogDebug(@"webSocket:didFailWithError: %@", error);
    [self setWebSocket:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    LogDebug(@"webSocket:didCloseWithCode: %i reason: %@ wasClean: %i", code, reason, wasClean);
	[self webSocketDisconnect];
}

@end
