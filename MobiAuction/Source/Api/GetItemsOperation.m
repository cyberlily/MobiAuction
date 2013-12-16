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

#import "GetItemsOperation.h"

#import "GTMHTTPFetcher.h"
#import "HttpConstants.h"
#import "Logging.h"
#import "NSManagedObjectContext+EntityUpdate.h"
#import "NSMutableURLRequest+API.h"
#import "User.h"

@implementation GetItemsOperation

- (id)initOperation:(NSManagedObjectContext *)srcManagedObjectContext {
    self = [super initOperation:srcManagedObjectContext];

    if (self) {
        [self setMainThread:YES]; // needs main thread for GTMHTTPFetcher callbacks
    }

    return self;
}

- (void)apiCall {
#if DEBUG
    NSAssert([self auctionuid], @"invalid parameter");
#endif

    NSDictionary *parameters = @{
        kParamAction:kActionItemList,
        kParamAuctionUid:[[self auctionuid] stringValue]
    };
    
    NSString *requestUrl = [kApiUrl stringByAppendingString:@"/event"];
    NSMutableURLRequest *request = [NSMutableURLRequest signedRequest:requestUrl withParams:parameters];

    GTMHTTPFetcher *itemFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [itemFetcher beginFetchWithDelegate:self didFinishSelector:@selector(itemFetcher:finishedWithData:error:)];
}

- (void)itemFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error {
    if (error != nil) {
        [self apiMessage:NSLocalizedString(@"ERROR_NETWORK", nil)];
        LogError(@"%@", [error localizedDescription]);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:retrievedData encoding:NSASCIIStringEncoding];
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

        id errors = [jsonDict valueForKey:@"errors"];
        if (errors != nil) {
            [self apiMessage:NSLocalizedString(@"ERROR_SERVER", nil)];
            LogError(@"%@", [error localizedDescription]);
        } else {
            NSMutableDictionary *itemsDict = [NSMutableDictionary dictionary];

            NSArray *itemsArr = [jsonDict valueForKey:@"items"];
            unsigned int total = [itemsArr count];
            for (unsigned int i = 0; i < total; i++) {
                NSMutableDictionary *itemDict = [itemsArr[i] mutableCopy];
                
                // Need to rename the description field since that is a reserved name in core data
                itemDict[@"desc"] = itemDict[@"description"];
                [itemDict removeObjectForKey:@"description"];

                [itemsDict setValue:itemDict forKey:itemDict[@"uid"]];
            }

            LogDebug(@"%@", itemsDict);

            NSManagedObjectContext *context = [self apiManagedObjectContext];
            [context updateEntity:@"Item"
                    forEntityType:nil
                    fromDictionary:itemsDict
                    withIdentifier:@"uid"
                    overwriting:@[@"uid", @"itemNumber", @"name", @"desc", @"category", @"seller", @"valPrice", @"minPrice", @"incPrice", @"curPrice", @"bidCount", @"watchCount", @"winner", @"url", @"multi"]
                    removing:NO
                    andError:&error];

            if (error != nil) {
                [self apiMessage:NSLocalizedString(@"ERROR_SERVER", nil)];
                LogError(@"%@", [error localizedDescription]);
            } else {
                [self apiSave]; // save the changes
            }
        }
    }

    [self apiFinished]; // signal the queue
}

@end
