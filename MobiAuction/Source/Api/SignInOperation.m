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

#import "SignInOperation.h"

#import "GTMHTTPFetcher.h"
#import "HttpConstants.h"
#import "Logging.h"
#import "NSManagedObjectContext+EntityUpdate.h"
#import "NSMutableURLRequest+API.h"

@interface SignInOperation (PrivateMethods)
- (void)handleError;
@end

@implementation SignInOperation

- (id)initOperation:(NSManagedObjectContext *)srcManagedObjectContext {
    self = [super initOperation:srcManagedObjectContext];

    if (self) {
        [self setMainThread:YES]; // needs main thread for GTMHTTPFetcher callbacks
    }

    return self;
}

- (void)apiCall {
#if DEBUG
    NSAssert([self biddernumber], @"invalid parameter");
    NSAssert([self password], @"invalid parameter");
#endif

    NSDictionary *parameters = @{
        kParamAction: kActionSignIn,
        kParamBidderNumber: [self biddernumber],
        kParamPassword: [self password]
    };
    
    NSString *requestUrl = [kApiUrl stringByAppendingString:@"/auth"];
    NSMutableURLRequest *request = [NSMutableURLRequest signedRequest:requestUrl withParams:parameters];

    GTMHTTPFetcher *itemFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [itemFetcher beginFetchWithDelegate:self didFinishSelector:@selector(itemFetcher:finishedWithData:error:)];
}

- (void)itemFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error {
    if (error != nil) {
        [self handleError];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:retrievedData encoding:NSASCIIStringEncoding];
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        
        if (jsonDict == nil) {
            [self handleError];
        } else {
            NSArray *errorArr = [jsonDict valueForKey:@"errors"];
            if ([errorArr count] > 0) {
                [self handleError];
            } else {
                NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
                NSMutableDictionary *userDict = [jsonDict mutableCopy];
                [userDict setValue:[self password] forKey:@"password"];

                [usersDict setValue:userDict forKey:userDict[@"bidderNumber"]];
                
                LogDebug(@"%@", usersDict);
                
                NSManagedObjectContext *context = [self apiManagedObjectContext];
                [context updateEntity:@"User"
                    forEntityType:nil fromDictionary:usersDict
                    withIdentifier:@"bidderNumber"
                    overwriting:@[@"uid", @"bidderNumber", @"password", @"auctionUid", @"firstName", @"lastName", @"sessionId"]
                    removing:NO andError:&error];
                
                if (error != nil) {
                    [self apiMessage:NSLocalizedString(@"ERROR_SERVER", nil)];
                    LogError(@"%@", [error localizedDescription]);
                } else {
                    [self apiSave]; // save the changes
                }
            }
        }
    }
    
    [self apiFinished]; // signal the queue
}

- (void)handleError {
    NSManagedObjectContext *context = [self apiManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:1]; // only 1
    
    NSArray *fetchResult = [context executeFetchRequest:fetchRequest error:nil];
    if ((fetchResult != nil) && ([fetchResult count] > 0)) {
        [context deleteObject:fetchResult[0]];
    }
    
    fetchRequest = nil;
}

@end
