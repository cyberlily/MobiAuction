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
#import "Reachability.h"
#import "RegisterDeviceOperation.h"
#import "SignInOperation.h"
#import "User.h"
#import "YRDropdownView.h"
#import "SRWebSocket.h"

@interface AppDelegate (PrivateMethods)
- (void)setVersion;

- (void)subscribeToWebSockets;
- (void)unsubscribeFromWebSockets;

- (void)onWebSocketItemUpdateMessage:(NSDictionary *)event;
- (void)onWebSocketFundUpdateMessage:(NSDictionary *)event;

- (void)onSigninComplete:(NSNotification *)notification;

- (void)onApiOperationMessage:(NSNotification *)notification;
- (void)updateApiOperationMessage:(NSString*)message; // update ui on main thread after NSOpertion completion

-(void)setUpRechability;
- (void)handleNetworkChange:(NSNotification *)notice;
@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize user = _user;
@synthesize hostReachability = _hostReachability;

- (void)dealloc {        
    [self unsubscribeFromWebSockets];
    
    AudioServicesDisposeSystemSoundID(_notificationSound);
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc removeObserver:self name:kApiOperationMessage object:nil];
    [dnc removeObserver:self name:kSigninComplete object:nil];
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

    return YES;
}

- (void)subscribeToWebSockets {
    [self setWebSocketClient:[[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kWebSocketUrl]]]];
    [[self webSocketClient] setDelegate:self];
    [[self webSocketClient] open];
}

- (void)unsubscribeFromWebSockets {
    [[self webSocketClient] setDelegate:nil];
    [[self webSocketClient] close];
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
    [self showMessage:NSLocalizedString(@"WARNING_REGISTRATION", nil) hideAfter:5.0];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self showMessage:userInfo[@"aps"][@"alert"] hideAfter:5.0];
    
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

    [dnc addObserver:self selector:@selector(onApiOperationMessage:) name:kApiOperationMessage object:nil];
    
    [dnc postNotificationName:kRefreshView object:self userInfo:nil];

    [self setUpRechability];
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
            [self showMessage:NSLocalizedString(@"ERROR_SAVECONTEXT", nil) hideAfter:5.0];
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

- (bool)showMessage:(NSString *)message hideAfter:(float)delay {
    [YRDropdownView showDropdownInView:[self window] title:kAppName detail:message image:nil animated:YES hideAfter:delay];    
    return YES;
}

- (bool)hideMessage {
    return[YRDropdownView hideDropdownInView:[self window]];
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
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    LogDebug(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    LogDebug(@":( Websocket Failed With Error %@", error);
    [self setWebSocketClient:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    LogDebug(@"Received \"%@\"", message);

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

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    LogDebug(@"WebSocket closed");
    [self setWebSocketClient:nil];

    [self setUpRechability];
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
    [self showMessage:message hideAfter:5.0];
}

- (void)setUpRechability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];

    _hostReachability = [Reachability reachabilityForInternetConnection];
    [[self hostReachability] startNotifier];

    NetworkStatus hostStatus = [[self hostReachability] currentReachabilityStatus];

    if(hostStatus == NotReachable) {
        [self unsubscribeFromWebSockets];
    } else {
        [self unsubscribeFromWebSockets];
        [self subscribeToWebSockets];
    }
}

- (void)handleNetworkChange:(NSNotification *)notice {
    NetworkStatus hostStatus = [[self hostReachability] currentReachabilityStatus];

    if(hostStatus == NotReachable) {
        [self unsubscribeFromWebSockets];
    } else {
        [self unsubscribeFromWebSockets];
        [self subscribeToWebSockets];
    }
}

@end
