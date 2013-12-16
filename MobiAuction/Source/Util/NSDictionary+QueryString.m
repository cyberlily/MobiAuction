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

#import "NSDictionary+QueryString.h"

#import "NSString+URLEncoding.h"

@implementation NSDictionary (NSDictionary_QueryString)

- (NSString *)queryString {
    NSMutableString *queryString = nil;

    NSArray *keys = [self allKeys];
    if ([keys count] > 0) {
        for (id key in keys) {
            id value = self[key];
            if (nil == queryString) {
                queryString = [[NSMutableString alloc] init];
                [queryString appendFormat:@"?"];
            } else {
                [queryString appendFormat:@"&"];
            }

            if (nil != key && nil != value) {
                [queryString appendFormat:@"%@=%@", [key urlEncodeUsingEncoding:NSUTF8StringEncoding], [value urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            } else if (nil != key) {
                [queryString appendFormat:@"%@", [key urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }

    return queryString;
}

- (NSString *)querySignatureString {
    NSMutableString *queryString = nil;

    NSArray *keys = [self allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
    if ([sortedKeys count] > 0) {
        for (id key in sortedKeys) {
            id value = self[key];
            if (nil == queryString) {
                queryString = [[NSMutableString alloc] init];
                [queryString appendFormat:@"?"];
            } else {
                [queryString appendFormat:@"@"];
            }

            if (nil != key && nil != value) {
                [queryString appendFormat:@"%@$%@", [key urlEncodeUsingEncoding:NSUTF8StringEncoding], [value urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            } else if (nil != key) {
                [queryString appendFormat:@"%@", [key urlEncodeUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }

    return queryString;
}

@end
