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

#import "NSMutableURLRequest+API.h"

#import "AppConstants.h"
#import "HttpConstants.h"
#import "NSURL+PathParameters.h"
#import "NSDictionary+QueryString.h"
#import "NSString+MD5.h"

@implementation NSMutableURLRequest (NSMutableURLRequest_API)

+ (NSMutableURLRequest *)signedRequest:(NSString *)urlString withParams:(NSDictionary *)params {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    unsigned long long timestampVal = (unsigned long long) timeInterval;
    NSString *timestamp = [NSString stringWithFormat:@"%qu", timestampVal];

    NSURL *url = [NSURL URLWithString:urlString];
    url = [url URLByAppendingParameters:params];

    NSMutableDictionary *signatureDict = [[NSMutableDictionary alloc] initWithDictionary:params];
    signatureDict[kApiTimestamp] = timestamp;
    signatureDict[kApiAppKey] = kAppKey;

    NSMutableString *temp = [[NSMutableString alloc] initWithString:[url path]];
    [temp appendString:[signatureDict querySignatureString]];
    [temp appendString:kAppSecret];

    NSString *signature = [[temp stringByReplacingOccurrencesOfString:@"%20" withString:@""] MD5];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"GET"];
    [request addValue:kAppKey forHTTPHeaderField:kApiAppKey];
    [request addValue:signature forHTTPHeaderField:kApiSignature];
    [request addValue:timestamp forHTTPHeaderField:kApiTimestamp];

    return request;
}

@end
