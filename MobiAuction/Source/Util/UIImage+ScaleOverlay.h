//
//  UIImage+ScaleOverlay.h
//  iOSAuction
//
//  Created by Samuel Taylor on 7/5/12.
//  Copyright (c) 2012 mobiaware.com. All rights reserved.
//

@interface UIImage (UIImage_ScaleOverlay)

- (UIImage *)scaleToSize:(CGSize)scaleSize andOverlayWith:(UIImage *)overlayImage andSize:(CGSize)overlaySize;

- (UIImage *)scaleToSize:(CGSize)scaleSize andCombineWith:(UIImage *)combineImage andSize:(CGSize)combineSize;

@end
