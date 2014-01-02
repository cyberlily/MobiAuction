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
#import <AudioToolbox/AudioToolbox.h>

#import "Reachability.h"
#import "SRWebSocket.h"
#import "User.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, SRWebSocketDelegate> {

}

@property(readwrite, nonatomic, strong) UIWindow *window;
@property(readwrite, nonatomic, strong) UINavigationController *navigationController;

@property(readonly, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(readonly, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property(readonly, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property(readonly, nonatomic, strong) User *user;

@property(readwrite, nonatomic, strong) SRWebSocket *webSocketClient;

@property (readwrite, nonatomic, assign) SystemSoundID notificationSound;

@property(readonly, nonatomic, strong) Reachability *hostReachability;

- (void)saveContext;

- (NSURL *)applicationDocumentsDirectory;

- (NSNumber*) auctionUid; // fetch from User first but support Kiosk

- (bool)showMessage:(NSString *)message hideAfter:(float)delay;
- (bool)hideMessage;

- (void)reset;

@end