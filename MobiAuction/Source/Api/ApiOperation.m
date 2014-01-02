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

#import "ApiOperation.h"

#import "Logging.h"

NSString *const kApiOperationMessage = @"apioperationmessage";

@interface ApiOperation (PrivateMethods)
- (void)contextDidSave:(NSNotification *)notification;
@end

@implementation ApiOperation

- (id)initOperation:(NSManagedObjectContext *)srcManagedObjectContext {
    self = [super init];

    if (self) {
        [self setSrcManagedObjectContext:srcManagedObjectContext];
    }

    return self;
}

- (NSManagedObjectContext *)apiManagedObjectContext {
    // Create a separate managed object context for the operations, and set its undo manager to nil.
    if (_apiManagedObjectContext != nil) {
        return _apiManagedObjectContext;
    }

    NSManagedObjectContext *context = [self srcManagedObjectContext];

    NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
    _apiManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [_apiManagedObjectContext setPersistentStoreCoordinator:coordinator];
    [_apiManagedObjectContext setUndoManager:nil];

    return _apiManagedObjectContext;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isFinished {
    return _finished;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isCancelled {
    return _cancelled;
}

- (void)cancel {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = YES;
    [self didChangeValueForKey:@"isCancelled"];

    [self apiFinished]; // signal the queue	
}

- (void)start {
    LogDebug(@"Begin operation. %@ %p", [self class], self);

    // Ensure this operation is not being restarted and that it has not been cancelled
    if ([self isFinished] || [self isCancelled]) {
        [self apiFinished]; // signal the queue
        return;
    }

    // From this point on, the operation is officially executing--remember, isExecuting needs to be KVO compliant!
    [self setExecuting:YES];

    // Begin the background operation
    //
    // Some operations that use the NSURLConnection API need to run on the main thread in order
    // handle callbacks. So make a switch here based on the caller.
    if ([self mainThread]) {
        [self performSelectorOnMainThread:@selector(apiCall) withObject:nil waitUntilDone:NO]; // on main thread for callbacks
    } else {
        [self performSelector:@selector(apiCall)]; // on thread for callbacks
    }
}

- (void)apiCall {
    [self apiFinished]; // signal the queue
}

- (void)apiSave {
    // Merge changes causing the fetched results controller to update its results. We will emit
    // a change notification that the fetch results controller will observe to pick up the new list.
    NSManagedObjectContext *context = [self apiManagedObjectContext];

    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];

    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        LogError(@"%@", [error localizedDescription]);
    }

    [dnc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

- (void)contextDidSave:(NSNotification *)notification {
    NSManagedObjectContext *context = [self srcManagedObjectContext];
    [context performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
}

- (void)apiFinished {
    LogDebug(@"End operation. %@ %p", [self class], self);
    
    [self setSrcManagedObjectContext:nil];
    [self setApiManagedObjectContext:nil];

    // Alert anyone that we are finished
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _finished = YES;
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)apiMessage:(NSString*)message {
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:kApiOperationMessage object:message userInfo:nil];
}

@end

