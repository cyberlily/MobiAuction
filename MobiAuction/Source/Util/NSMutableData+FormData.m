//
//  NSMutableData+FormData.m
//  iOSAuction
//
//  Created by Samuel Taylor on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSMutableData+FormData.h"

@implementation NSMutableData (NSMutableData_FormData)

- (NSString *)encodeURL:(NSString *)string {
    NSString *newString = NSMakeCollectable([(NSString *) CFURLCreateStringByAddingPercentEscapes
            (kCFAllocatorDefault, (CFStringRef) string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                    CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease]);
    if (newString) {
        return newString;
    }
    return @"";
}

- (void)addPostValue:(NSString *)value forKey:(NSString *)key andMore:(BOOL)more {
    NSString *string = [NSString stringWithFormat:@"%@=%@%@", [self encodeURL:key], [self encodeURL:value], (more ? @"&" : @"")];
    [self appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
