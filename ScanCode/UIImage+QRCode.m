//
//  UIImage+QRCode.m
//  REnextop
//
//  Created by Sean on 16/6/23.
//  Copyright © 2016年 ZhangHeng. All rights reserved.
//

#define kQRCode_Size 207.f
#define kDefault_Radius 5.f
#define kCenterImage [UIImage imageNamed:@"default_avatar"]

#import "UIImage+QRCode.h"
#import <CoreImage/CoreImage.h>

void ProviderReleaseData(void *info, const void *data, size_t size) {
    free((void *)data);
}

void addRoundRectToPath(CGContextRef context, CGRect rect, float radius, CGImageRef image)
{
    float width, height;
    if (radius == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    width = CGRectGetWidth(rect);
    height = CGRectGetHeight(rect);
    
    //裁剪路径
    CGContextMoveToPoint(context, width, height / 2);
    CGContextAddArcToPoint(context, width, height, width / 2, height, radius);
    CGContextAddArcToPoint(context, 0, height, 0, height / 2, radius);
    CGContextAddArcToPoint(context, 0, 0, width / 2, 0, radius);
    CGContextAddArcToPoint(context, width, 0, width, height / 2, radius);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRestoreGState(context);
}

@implementation UIImage (QRCode)
+ (UIImage *)QRIamgeOfContent:(NSString *)content {
    return [self QRIamgeOfContent:content andColor:[UIColor blackColor] centerImage:kCenterImage andRaduis:kDefault_Radius];
}

+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color {
    return [self QRIamgeOfContent:content andColor:color centerImage:kCenterImage andRaduis:kDefault_Radius];
}

+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color centerImage:(UIImage *)centerImage {
    return [self QRIamgeOfContent:content andColor:color centerImage:centerImage andRaduis:kDefault_Radius];
}

+ (UIImage *)QRIamgeOfContent:(NSString *)content andColor:(UIColor *)color centerImage:(UIImage *)centerImage andRaduis:(CGFloat)roundRadius {
    if (!content || content.length == 0) {
        return nil;
    }
    CGFloat size = kQRCode_Size;
    
    //生成原始的二维码图片(模糊)
    CIImage *originImage = [self createQRImageFromContent:content];
    
    //对图片做清晰处理
    UIImage *sharpImage = [self sharpImageWithCIImage:originImage andSize:size];
    
    //上色
    UIImage *resultImage = [self imageFillColor:sharpImage andColor:color];
    
    if (centerImage) {
        resultImage = [UIImage drawImage:resultImage withCenterImage:centerImage withRadius:roundRadius];
    }
    
    return resultImage;
}

+ (CIImage *)createQRImageFromContent:(NSString *)content {
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:contentData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    return qrFilter.outputImage;
}

+ (UIImage *)sharpImageWithCIImage:(CIImage *)resource andSize:(CGFloat)size {
    CGRect extent = CGRectIntegral(resource.extent);
    
    CGFloat scale = MIN(size / CGRectGetWidth(extent), size / CGRectGetHeight(extent));
    
    size_t width  = CGRectGetWidth(extent)  * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    
    //创建灰度色调空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef bitmapImage = [context createCGImage:resource fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    CGColorSpaceRelease(colorSpace);
    
    return [UIImage imageWithCGImage:scaledImage];
}

+ (UIImage *)imageFillColor:(UIImage *)resource andColor:(UIColor *)color {
    const int imageWidth  = resource.size.width;
    const int imageHeight = resource.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t *rgbImageBuf = (uint32_t *)malloc(bytesPerRow * imageHeight);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), resource.CGImage);
    
    //遍历像素
    int pixelNumber = imageHeight * imageWidth;
    [self transparentedWhiteOnPixel:rgbImageBuf pixelNum:pixelNumber withColor:color];
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(nil, rgbImageBuf, bytesPerRow, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaLast, dataProvider, nil, true, kCGRenderingIntentDefault);
    
    UIImage * resultImage = [UIImage imageWithCGImage: imageRef];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return resultImage;
}

+ (void)transparentedWhiteOnPixel:(uint32_t *)rgbImageBuf pixelNum:(int)pixelNum withColor:(UIColor *)color {
    uint32_t *pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++) {
        if ((*pCurPtr & 0xffffff00) < 0x99999900) {
            uint8_t *ptr = (uint8_t *)pCurPtr;
            ptr[3] = color.red * 255.f;
            ptr[2] = color.green * 255.f;
            ptr[1] = color.blue * 255.f;
        } else {
            uint8_t *ptr = (uint8_t *)pCurPtr;
            ptr[0] = 0;
        }
    }
}

+ (UIImage *)drawImage:(UIImage *)originImage withCenterImage:(UIImage *)centerImage withRadius:(CGFloat)radius {
    if (!centerImage) {return originImage;}
    
    centerImage = [self drawMasktedImage:centerImage WithSize:centerImage.size radius:radius];
    
    
    UIImage *whiteBg = [UIImage imageWithColor:[UIColor whiteColor]];
    whiteBg = [self drawMasktedImage:whiteBg WithSize:centerImage.size radius:radius];
    
    const CGFloat whiteSize = 2.f;
    
    //外面白色边缘的坐标
    CGSize brinkSize = CGSizeMake(originImage.size.width/4.f, originImage.size.height/4.f);
    CGFloat brinkX = (originImage.size.width - brinkSize.width) / 2.f;
    CGFloat brinkY = (originImage.size.height - brinkSize.height) / 2.f;
    
    //logo的frame
    CGSize imageSize = CGSizeMake(brinkSize.width - 2*whiteSize, brinkSize.height - 2*whiteSize);
    CGFloat imageX = brinkX + whiteSize;
    CGFloat imageY = brinkY + whiteSize;
    
    UIGraphicsBeginImageContext(originImage.size);
    //绘制二维码图片
    [originImage drawInRect:CGRectMake(0, 0, originImage.size.width, originImage.size.height)];
    //绘制白色背景
    [whiteBg drawInRect:CGRectMake(brinkX, brinkY, brinkSize.width, brinkSize.height)];
    //绘制logo图片
    [centerImage drawInRect:CGRectMake(imageX, imageY, imageSize.width, imageSize.height)];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

+ (UIImage *)drawMasktedImage:(UIImage *)originImage WithSize:(CGSize)size radius:(CGFloat)radius {
    const CGFloat width  = size.width;
    const CGFloat height = size.height;
    
    radius = MAX(5.f, radius);
    radius = MIN(10.f, radius);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 4*width, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextBeginPath(context);
    addRoundRectToPath(context, CGRectMake(0, 0, width, height), radius, originImage.CGImage);
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    UIImage *reulstImage = [UIImage imageWithCGImage:imageMasked];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageMasked);
    
    return reulstImage;
}
@end

@implementation UIColor (Expanded)
- (BOOL)canProvideRGBComponents {
    switch (self.colorSpaceModel) {
        case kCGColorSpaceModelRGB:
        case kCGColorSpaceModelMonochrome:
            return YES;
        default:
            return NO;
    }
}

- (CGColorSpaceModel)colorSpaceModel {
    return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (CGFloat)red {
    NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -red");
    const CGFloat *c = CGColorGetComponents(self.CGColor);
    return c[0];
}

- (CGFloat)green {
    NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -green");
    const CGFloat *c = CGColorGetComponents(self.CGColor);
    if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
    return c[1];
}

- (CGFloat)blue {
    NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -blue");
    const CGFloat *c = CGColorGetComponents(self.CGColor);
    if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
    return c[2];
}

- (CGFloat)white {
    NSAssert(self.colorSpaceModel == kCGColorSpaceModelMonochrome, @"Must be a Monochrome color to use -white");
    const CGFloat *c = CGColorGetComponents(self.CGColor);
    return c[0];
}
@end

@implementation UIImage (ColorImage)
+ (UIImage *)imageWithColor:(UIColor *)aColor {
    return [UIImage imageWithColor:aColor withFrame:CGRectMake(0, 0, 1, 1)];
}

+ (UIImage *)imageWithColor:(UIColor *)aColor withFrame:(CGRect)aFrame {
    UIGraphicsBeginImageContext(aFrame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [aColor CGColor]);
    CGContextFillRect(context, aFrame);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
@end
