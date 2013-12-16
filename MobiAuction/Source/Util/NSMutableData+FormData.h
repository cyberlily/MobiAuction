//
//  NSMutableData+FormData.h
//  iOSAuction
//
//  Created by Samuel Taylor on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableData (NSMutableData_FormData)

- (NSString *)encodeURL:(NSString *)string;

- (void)addPostValue:(NSString *)value forKey:(NSString *)key andMore:(BOOL)more;

@end
