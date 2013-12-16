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

#import <Foundation/Foundation.h>

extern NSString *const kApiOperationMessage; // called when an operation needs to signal a message

@interface ApiOperation : NSOperation {
@private
    // In concurrent operations, we have to manage the operation's state
    BOOL _executing;
    BOOL _finished;
    BOOL _cancelled;
}

// The src context is the context we will save data back to. Typically this would be the main context
// but there are cases during edit or adding of objects where we might want to save it back to another
// temp context for processing.
@property(readwrite, nonatomic, strong) NSManagedObjectContext *srcManagedObjectContext;

// Use a temp context for the API request
@property(readwrite, nonatomic, strong) NSManagedObjectContext *apiManagedObjectContext;

// Switch used to signal thread on which to run operation
@property(readwrite, nonatomic, assign) BOOL mainThread;

- (id)initOperation:(NSManagedObjectContext *)srcManagedObjectContext;

- (void)setFinished:(BOOL)finished;
- (void)setExecuting:(BOOL)executing;

// API call
- (void)apiCall;

// Used to save the temp context back to the main thread context. Generally this should not be called from 
// outside this class (or subclass). This is called by the fetch methods to trigger a save to main context.
- (void)apiSave;

// Generally this should not be called from outside this class (or subclasses). This is called by the fetch
// methods once they complete to clean up of the concurrent operation.
- (void)apiFinished;

// Allow operations to signal messages to listeners
- (void)apiMessage:(NSString*)message;

@end
