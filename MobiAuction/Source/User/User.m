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
 
#import "User.h"

#import "AppConstants.h"
#import "Logging.h"
#import "STKeychain.h"

@implementation User

- (NSString*)password {
    NSString *keyname = [NSString stringWithFormat:kKeychainPasswordName, [self uid]];
    LogInfo(@"Reading password from keychain. (%@)", keyname);
		
#if TARGET_IPHONE_SIMULATOR
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:keyname];
#else
    return [STKeychain getPasswordForUsername:keyname andServiceName:kKeychainServiceName error:nil];
#endif
}

- (void)setPassword:(NSString*)password {
    NSString *keyname = [NSString stringWithFormat:kKeychainPasswordName, [self uid]];
    LogInfo(@"Reading password from keychain. (%@)", keyname);

#if TARGET_IPHONE_SIMULATOR
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (password == nil) {
		[defaults removeObjectForKey:keyname];
	} else {
		[defaults setValue:password forKey:keyname];
	}
    [defaults synchronize];
#else
	if (password == nil) {
		[STKeychain deleteItemForUsername:keyname andServiceName:kKeychainServiceName error:nil];
	} else {
		[STKeychain storeUsername:keyname andPassword:password forServiceName:kKeychainServiceName updateExisting:YES error:nil];
	}
#endif
}

- (NSInteger) winningCount {
    NSManagedObjectContext *context = [self managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
//    NSExpression *lhs = [NSExpression expressionForKeyPath:@"winner"];
//    NSExpression *rhs = [NSExpression expressionForConstantValue:[self bidderNumber]];
//    NSPredicate *winnerequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
//        rightExpression:rhs
//        modifier:NSDirectPredicateModifier
//        type:NSEqualToPredicateOperatorType
//        options:NSCaseInsensitivePredicateOption| NSDiacriticInsensitivePredicateOption];
    NSPredicate *winnerequals = [NSPredicate predicateWithFormat:@"isWinning == %@", @YES];
    [fetchRequest setPredicate:winnerequals];
    
    NSInteger fetchCount = [context countForFetchRequest:fetchRequest error:nil];
            
    fetchRequest = nil;
    
    return fetchCount;
}

- (NSInteger) losingCount {
    NSManagedObjectContext *context = [self managedObjectContext];
 
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSMutableArray *andPredicates = [[NSMutableArray alloc] init];

    {
//        NSExpression *lhs = [NSExpression expressionForKeyPath:@"winner"];
//        NSExpression *rhs = [NSExpression expressionForConstantValue:[self bidderNumber]];
//        NSPredicate *winnernotequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
//            rightExpression:rhs
//            modifier:NSDirectPredicateModifier
//            type:NSNotEqualToPredicateOperatorType
//            options:NSCaseInsensitivePredicateOption| NSDiacriticInsensitivePredicateOption];
        NSPredicate *winnernotequals = [NSPredicate predicateWithFormat:@"isWinning != %@", @YES];
        [andPredicates addObject:winnernotequals];
    }
    {
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"hasBid"];
        NSExpression *rhs = [NSExpression expressionForConstantValue:@1];
        NSPredicate *hasbidequals = [NSComparisonPredicate predicateWithLeftExpression:lhs
            rightExpression:rhs
            modifier:NSDirectPredicateModifier
            type:NSEqualToPredicateOperatorType
            options:0];
        [andPredicates addObject:hasbidequals];
    }
    
    [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:andPredicates]];
    
    andPredicates = nil;
    
    NSInteger fetchCount = [context countForFetchRequest:fetchRequest error:nil];

    fetchRequest = nil;
    
    return fetchCount;
}

@end
