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

#import "ApiOperationService.h"

NSString *const kApiOperationServiceComplete = @"apioperationservicecomplete";

@implementation ApiOperationService

static ApiOperationService *singletonInstance = nil;

@synthesize operationQueue = _operationQueue;

+ (ApiOperationService *) instance {
    @synchronized(self) {
        if(!singletonInstance) {
            singletonInstance = [[ApiOperationService alloc] init];
        }
    }
 
    return singletonInstance;
}

- (NSOperationQueue *)operationQueue {
    if (_operationQueue != nil) {
        return _operationQueue;
    }
    
    _operationQueue = [[NSOperationQueue alloc] init];
    [_operationQueue setName:@"API Service Queue"];
    [_operationQueue setMaxConcurrentOperationCount:1];
    [_operationQueue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
    
    return _operationQueue;
}

- (void)suspendService {
    [[self operationQueue] setSuspended:YES];
}

- (void)resumeService {
    [[self operationQueue] setSuspended:NO];
}

- (void)cancelAllOperations {
    [[self operationQueue] cancelAllOperations];
}

- (void)addOperation:(ApiOperation *)operation {
    [[self operationQueue] addOperation:operation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (([keyPath isEqualToString:@"operationCount"]) && (object == [self operationQueue])) {
        if ([[self operationQueue] operationCount] == 0) {
            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            [dnc postNotificationName:kApiOperationServiceComplete object:self userInfo:nil];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

