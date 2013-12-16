//
//  ItemImageCache.m
//  iOSAuction
//
//  Created by Samuel Taylor on 7/5/12.
//  Copyright (c) 2012 mobiaware.com. All rights reserved.
//

#import "ItemImageCache.h"

#import "AppDelegate.h"
#import "Item.h"

@implementation ItemImageCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
return nil;
/*
    NSString *pathString = [[request URL] absoluteString];

    // if already a local file request (most likely) or not an image then return the default cache response
    if (([pathString rangeOfString:@"file://"].location != NSNotFound) ||
            (([pathString rangeOfString:@".png"].location == NSNotFound) &&
                    ([pathString rangeOfString:@".jpg"].location == NSNotFound) &&
                    ([pathString rangeOfString:@".gif"].location == NSNotFound))) {
        return [super cachedResponseForRequest:request];
    }

    // Check the core data and see if we have an image for this request
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(image=%@)", pathString]];

    NSArray *items = [context executeFetchRequest:fetchRequest error:nil];

    [fetchRequest release], fetchRequest = nil;

    // no item found for this request so return the default cache response
    if ([items count] == 0) {
        return [super cachedResponseForRequest:request];
    }

    Item *item = (Item *) items[0];

    // no image has been downloaded for this request yet
    if (!item.hasImage) {
        return [super cachedResponseForRequest:request];
    }

    // return image as png
    UIImage *tempImage = [item imagethumbnail];
    NSData *imageData = UIImagePNGRepresentation(tempImage);
    NSURLResponse *response = [[[NSURLResponse alloc]
            initWithURL:[request URL]
               MIMEType:@"image/png"
  expectedContentLength:[imageData length]
       textEncodingName:nil] autorelease];

    return [[[NSCachedURLResponse alloc] initWithResponse:response data:imageData] autorelease];
    */
}

@end
