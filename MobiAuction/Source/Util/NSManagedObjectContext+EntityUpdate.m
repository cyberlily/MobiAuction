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
#import "NSManagedObjectContext+EntityUpdate.h"

#import "Logging.h"

@implementation NSManagedObjectContext (NSManagedObjectContext_UpdateEntity)

- (BOOL)updateEntity:(NSString *)entity fromDictionary:(NSDictionary *)importDict withIdentifier:(NSString *)identifier overwriting:(NSArray *)overwritables andError:(NSError **)error {
    return [self updateEntity:entity forEntityType:nil fromDictionary:importDict withIdentifier:identifier overwriting:overwritables andError:error];
}

- (BOOL)updateEntity:(NSString *)entity forEntityType:(NSString *)entityType fromDictionary:(NSDictionary *)importDict withIdentifier:(NSString *)identifier overwriting:(NSArray *)overwritables andError:(NSError **)error {
    return [self updateEntity:entity forEntityType:entityType fromDictionary:importDict withIdentifier:identifier overwriting:overwritables removing:YES andError:error];
}

- (BOOL)updateEntity:(NSString *)entity forEntityType:(NSString *)entityType fromDictionary:(NSDictionary *)importDict withIdentifier:(NSString *)identifier overwriting:(NSArray *)overwritables removing:(BOOL)remove andError:(NSError **)error {
    return [self updateEntity:entity forEntityType:entityType withPredicate:nil fromDictionary:importDict withIdentifier:identifier overwriting:overwritables removing:remove andError:error];
}

- (BOOL)updateEntity:(NSString *)entity forEntityType:(NSString *)entityType withPredicate:(NSPredicate *)predicate fromDictionary:(NSDictionary *)importDict withIdentifier:(NSString *)identifier overwriting:(NSArray *)overwritables removing:(BOOL)remove andError:(NSError **)error {
    // Get the sorted import identifiers
    NSArray *identifiersToImport = [[importDict allKeys] sortedArrayUsingSelector:@selector(compare:)];

    // Get the entities as managed objects
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:self]];
    [fetchRequest setFetchBatchSize:20];
    if (predicate != nil) {
        [fetchRequest setPredicate:predicate];
    }

    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:identifier ascending:YES]]];

    NSArray *managedObjects = [self executeFetchRequest:fetchRequest error:error];

fetchRequest = nil;

    // Compare import identifiers with managed object identifiers
    NSEnumerator *importIterator = [identifiersToImport objectEnumerator];
    NSEnumerator *objectIterator = [managedObjects objectEnumerator];
    NSString *thisImportIdentifier = [importIterator nextObject];
    NSManagedObject *thisObject = [objectIterator nextObject];

    // Loop through both lists, comparing identifiers, until both are empty
    while (thisImportIdentifier || thisObject) {
        NSComparisonResult comparison;
        if (!thisImportIdentifier) {
            comparison = NSOrderedDescending; // If the import list has run out, the import identifier sorts last (i.e. remove remaining objects)
        } else if (!thisObject) {
            comparison = NSOrderedAscending; // If managed object list has run out, the import identifier sorts first (i.e. add remaining objects)
        } else {
            comparison = [thisImportIdentifier compare:[thisObject valueForKey:identifier]]; // If neither list has run out, compare with the object
        }

        if (comparison == NSOrderedSame) {
  
            if (overwritables) {
                      LogDebug(@"%@ %@", @"Data Storage:Merging item.", thisObject);

                // Merge the allowed non-identifier properties, if not nil
                NSDictionary *importAttributes = importDict[thisImportIdentifier];
                NSDictionary *overwriteAttributes = [NSDictionary dictionaryWithObjects:[importAttributes objectsForKeys:overwritables notFoundMarker:@""] forKeys:overwritables];
                [thisObject setValuesForKeysWithDictionary:overwriteAttributes];
            }

            thisObject = [objectIterator nextObject];
            thisImportIdentifier = [importIterator nextObject];

        } else if (comparison == NSOrderedAscending) {
            LogDebug(@"%@ %@", @"Data Storage:Adding item.", thisObject);

            NSMutableDictionary *dict = importDict[thisImportIdentifier];

            NSString *createEntity = entity;
            if ([entityType length] > 0) {
                createEntity = dict[entityType];
                [dict removeObjectForKey:entityType];
            }

            // The imported item is previously unseen - add it and move ahead to the next import identifier
            NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:createEntity inManagedObjectContext:self];
            [newObject setValue:thisImportIdentifier forKey:identifier];
            [newObject setValuesForKeysWithDictionary:dict];
            thisImportIdentifier = [importIterator nextObject];

        } else {
         
            // The stored item is not among those imported, and should be removed, then move ahead to the next stored item
            if (remove) {
               LogDebug(@"%@ %@", @"Data Storage:Removing data.", thisObject);

                [self deleteObject:thisObject];
            }

            thisObject = [objectIterator nextObject];
        }
    }

    return NO;
}

@end
