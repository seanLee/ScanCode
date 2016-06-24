//
//  UIImage+QRCode.h
//  REnextop
//
//  Created by Sean on 16/6/23.
//  Copyright © 2016年 ZhangHeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCode)
+ (UIImage *)QRIamgeOfContent:(NSString *)content;
+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color;
+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color centerImage:(UIImage *)centerImage;
+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color centerImage:(UIImage *)centerImage andRaduis:(CGFloat)roundRadius;

+ (UIImage *)drawMasktedImage:(UIImage *)originImage WithSize:(CGSize)size radius:(CGFloat)radius;
@end

@interface UIColor (Expanded)
@property (nonatomic, readonly) CGFloat red; // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat green; // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat blue; // Only valid if canProvideRGBComponents is YES
@end

@interface UIImage (ColorImage)
+ (UIImage *)imageWithColor:(UIColor *)aColor;
+ (UIImage *)imageWithColor:(UIColor *)aColor withFrame:(CGRect)aFrame;
@end
