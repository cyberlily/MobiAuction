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

#import <CoreData/CoreData.h>

@interface _Item : NSManagedObject {

}

// Core Data properties
@property(readwrite, nonatomic, strong) NSNumber *uid;
@property(readwrite, nonatomic, strong) NSString *itemNumber;
@property(readwrite, nonatomic, strong) NSString *name;
@property(readwrite, nonatomic, strong) NSString *desc;
@property(readwrite, nonatomic, strong) NSString *category;
@property(readwrite, nonatomic, strong) NSString *seller;
@property(readwrite, nonatomic, strong) NSDecimalNumber *valPrice;
@property(readwrite, nonatomic, strong) NSDecimalNumber *minPrice;
@property(readwrite, nonatomic, strong) NSDecimalNumber *incPrice;
@property(readwrite, nonatomic, strong) NSDecimalNumber *curPrice;
@property(readwrite, nonatomic, strong) NSNumber *bidCount;
@property(readwrite, nonatomic, strong) NSNumber *watchCount;
@property(readwrite, nonatomic, strong) NSNumber *hasBid;
@property(readwrite, nonatomic, strong) NSNumber *hasWatch;
@property(readwrite, nonatomic, strong) NSString *winner;
@property(readwrite, nonatomic, strong) NSString *url;
@property(readwrite, nonatomic, strong) NSNumber *multi;
@property(readwrite, nonatomic, strong) NSNumber *isWinning;

@end
