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

#import <Foundation/Foundation.h>

@interface ItemTableViewCell : UITableViewCell {

}

@property(readwrite, nonatomic, weak) IBOutlet UILabel *nameLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *itemLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *descLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *valPriceLabel;
@property(readwrite, nonatomic, weak) IBOutlet UILabel *curPriceLabel;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *favoriteImage;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *winningImage;
@property(readwrite, nonatomic, weak) IBOutlet UIImageView *losingImage;

@end
