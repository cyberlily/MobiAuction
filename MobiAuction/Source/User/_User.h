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

@interface _User : NSManagedObject {

}

// Core Data
@property(readwrite, nonatomic, strong) NSNumber *uid;
@property(readwrite, nonatomic, strong) NSNumber *auctionUid;
@property(readwrite, nonatomic, strong) NSString *bidderNumber;
@property(readwrite, nonatomic, strong) NSString *firstName;
@property(readwrite, nonatomic, strong) NSString *lastName;
@property(readwrite, nonatomic, strong) NSString *sessionId;

@end
