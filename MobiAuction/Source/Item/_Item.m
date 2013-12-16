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

#import "_Item.h"

#import "AppDelegate.h"

@implementation _Item

@dynamic uid;
@dynamic itemNumber;
@dynamic name;
@dynamic desc;
@dynamic category;
@dynamic seller;
@dynamic valPrice;
@dynamic minPrice;
@dynamic incPrice;
@dynamic curPrice;
@dynamic bidCount;
@dynamic watchCount;
@dynamic hasBid;
@dynamic hasWatch;
//@dynamic winner;
@dynamic url;
@dynamic multi;
@dynamic isWinning;

-(NSString *)winner
{
    [self willAccessValueForKey:@"winner"];
    NSString * winner = [self primitiveValueForKey:@"winner"];
    [self didAccessValueForKey:@"winner"];
    return winner;   
}

- (void)setWinner:(NSString *)winner
{
    [self willChangeValueForKey:@"winner"];
    [self setPrimitiveValue:winner forKey:@"winner"];
    [self didChangeValueForKey:@"winner"];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self setIsWinning:@([[[appDelegate user] bidderNumber] isEqualToString:winner])];
}

@end
