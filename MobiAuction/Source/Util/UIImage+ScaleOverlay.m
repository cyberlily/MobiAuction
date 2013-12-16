//
//  UIImage+ScaleOverlay.m
//  iOSAuction
//
//  Created by Samuel Taylor on 7/5/12.
//  Copyright (c) 2012 mobiaware.com. All rights reserved.
//

#import "UIImage+ScaleOverlay.h"

@implementation UIImage (UIImage_ScaleOverlay)

- (UIImage *)scaleToSize:(CGSize)scaleSize andOverlayWith:(UIImage *)overlayImage andSize:(CGSize)overlaySize {
    UIImage *combinedImage = nil;

    UIGraphicsBeginImageContext(scaleSize);
    [self drawInRect:CGRectMake(0, 0, scaleSize.width, scaleSize.height)];
    if (overlayImage != nil) {
        // This puts it in the lower right corner
        [overlayImage drawInRect:CGRectMake(scaleSize.width - overlaySize.width,
                scaleSize.height - overlaySize.height,
                overlaySize.width,
                overlaySize.height)
                       blendMode:kCGBlendModeNormal alpha:1.0];
    }
    combinedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return combinedImage;
}

- (UIImage *)scaleToSize:(CGSize)scaleSize andCombineWith:(UIImage *)combineImage andSize:(CGSize)combineSize {
    UIImage *combinedImage = nil;

    UIGraphicsBeginImageContext(scaleSize);
    [self drawInRect:CGRectMake(combineSize.width, 0, scaleSize.width + combineSize.width, scaleSize.height)];
    if (combineImage != nil) {
        [combineImage drawInRect:CGRectMake(0,
                0,
                combineSize.width,
                combineSize.height)
                       blendMode:kCGBlendModeNormal alpha:1.0];
    }
    combinedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return combinedImage;
}

@end
