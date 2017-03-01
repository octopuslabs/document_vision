//
//  CVWrapper.m
//  CVOpenTemplate
//
//  Created by Washe on 02/01/2013.
//  Copyright (c) 2013 foundry. All rights reserved.
//

#import "CVWrapper.h"
#import "UIImage+OpenCV.h"
#import "stitching.h"
#import "UIImage+Rotate.h"


@implementation CVWrapper

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
    NSArray* imageArray = [NSArray arrayWithObject:inputImage];
    UIImage* result = [[self class] processWithArray:imageArray];
    return result;
}

+ (UIImage*) processWithOpenCVImage1:(UIImage*)inputImage1 image2:(UIImage*)inputImage2;
{
    NSArray* imageArray = [NSArray arrayWithObjects:inputImage1,inputImage2,nil];
    UIImage* result = [[self class] processWithArray:imageArray];
    return result;
}

+ (UIImage*) processWithArray:(NSArray*)imageArray
{
    if ([imageArray count]==0){
        NSLog (@"imageArray is empty");
        return 0;
        }
    std::vector<cv::Mat> matImages;

    for (id image in imageArray) {
        if ([image isKindOfClass: [UIImage class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */
            UIImage* rotatedImage = [image rotateToImageOrientation];
            cv::Mat matImage = [rotatedImage CVMat3];
            NSLog (@"matImage: %@",image);
            matImages.push_back(matImage);
        }
    }
    NSLog (@"stitching...");
    cv::Mat stitchedMat = stitch (matImages);
    UIImage* result =  [UIImage imageWithCVMat:stitchedMat];
    return result;
}

+ (UIImage*) processCannyWithImage:(UIImage*)image
{
    if (![image isKindOfClass: [UIImage class]]) {
        return 0;
    }
    /*
     All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
     */
    UIImage* rotatedImage = [image rotateToImageOrientation];
    cv::Mat matImage = [rotatedImage CVMat3];
    NSLog (@"matImage: %@",image);
    
    cv::Mat cannyMat = cannyThreshold(matImage);
    
    UIImage* result =  [UIImage imageWithCVMat: cannyMat];
    return result;
}



+ (NSArray*) maxBoundingPolyWithImage:(UIImage*)image {
    if (![image isKindOfClass: [UIImage class]]) {
        return nil;
    }

    UIImage* rotatedImage = [image rotateToImageOrientation];
    cv::Mat matImage = [rotatedImage CVMat3];
    NSLog (@"matImage: %@",image);
    
    std::vector<cv::Point> points = maxBoundingBox(matImage);

    NSMutableArray *contourPoints = [NSMutableArray arrayWithCapacity:points.size()];
    
    for(const cv::Point &point : points)
    {
        CGPoint p = CGPointMake(point.x, point.y);
        [contourPoints addObject: [NSValue valueWithCGPoint:p]];
    }
    
    return [contourPoints copy];
}

@end
