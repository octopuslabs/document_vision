/////////////////////////
/*
 
 // stitching.cpp
 // adapted from stitching.cpp sample distributed with openCV source.
 // adapted by Foundry for iOS
 
 */



/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                          License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//

 M*/

#include "stitching.h"
#include <iostream>
#include <fstream>

//openCV 2.4.x
//#include "opencv2/stitching/stitcher.hpp"

//openCV 3.x
#include "opencv2/stitching.hpp"


using namespace std;
using namespace cv;

bool try_use_gpu = false;
vector<Mat> imgs;
string result_name = "result.jpg";

void printUsage();
int parseCmdArgs(int argc, char** argv);

cv::Mat stitch (vector<Mat>& images)
{
    imgs = images;
    Mat pano;
    Stitcher stitcher = Stitcher::createDefault(try_use_gpu);
    Stitcher::Status status = stitcher.stitch(imgs, pano);
    
    if (status != Stitcher::OK)
        {
        cout << "Can't stitch images, error code = " << int(status) << endl;
            //return 0;
        }
    return pano;
}

#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <stdlib.h>
#include <stdio.h>

using namespace cv;

// comparison function object
bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 ) {
    double i = fabs( contourArea(cv::Mat(contour1)) );
    double j = fabs( contourArea(cv::Mat(contour2)) );
    return ( i < j );
}

/**
 * @function CannyThreshold
 * @brief Trackbar callback - Canny thresholds input with a ratio 1:3
 */
//cv::Mat cannyThreshold(Mat src)
cv::Mat cannyThreshold(Mat src)
{
    Mat dst, detected_edges;
    
    int thresh = 100;
    int ratio2 = 3;
    int kernel_size = 3;
    
    Mat src_gray;
    /// Create a matrix of the same type and size as src (for dst)
    dst.create( src.size(), src.type() );
    
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, Size(3, 3) );
    
    /// Canny detector
    Canny( src_gray, dst, thresh, thresh*ratio2, kernel_size );
    
//    /// Using Canny's output as a mask, we display our result
//    dst = Scalar::all(0);
//    
//    src.copyTo( dst, detected_edges);
    return dst;

}

std::vector<cv::Point> maxBoundingBox(cv::Mat src) {
    Mat canny_output;
    vector<vector<Point> > contours;
    vector<Point> contours_poly;
    vector<Vec4i> hierarchy;
    vector<Point> screenCnt;
    
    canny_output = cannyThreshold(src);
    findContours( canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point(0, 0) );
    
    // sort contours
    std::sort(contours.begin(), contours.end(), compareContourAreas);

    //      approximate the contour
    std::vector<cv::Point> c = contours[contours.size() - 1];
    approxPolyDP( Mat ( c ), contours_poly, 20, true );

    return contours_poly;
    
//    for( int i = 1; i < contours.size(); i++)
//    {
//        // grab contours
//        std::vector<cv::Point> c = contours[contours.size() - i];
//        //      approximate the contour
//        approxPolyDP( Mat ( c ), contours_poly, 10, true );
//        
//        //      if our approximated contour has four points, then we
//        //      can assume that we have found our screen
//        if (contours_poly.size() >= 4) {
//            screenCnt = contours_poly;
//            break;
//        }
//    }
    
    
    return screenCnt;
}


//// DEPRECATED CODE //////
/*
 the code below this line is unused.
 it is derived from the openCV 'stitched' C++ sample
 left  in here only for illustration purposes
 
 - refactor main loop as member function
 - replace user input with iOS GUI
 - replace ouput with return value to CVWrapper
 
 */



//refactored as stitch function
int deprecatedMain(int argc, char* argv[])
{
    int retval = parseCmdArgs(argc, argv);
    if (retval) return -1;

    Mat pano;
    Stitcher stitcher = Stitcher::createDefault(try_use_gpu);
    Stitcher::Status status = stitcher.stitch(imgs, pano);

    if (status != Stitcher::OK)
    {
        cout << "Can't stitch images, error code = " << int(status) << endl;
        return -1;
    }

    imwrite(result_name, pano);
    return 0;
}

//unused
void printUsage()
{
    cout <<
        "Rotation model images stitcher.\n\n"
        "stitching img1 img2 [...imgN]\n\n"
        "Flags:\n"
        "  --try_use_gpu (yes|no)\n"
        "      Try to use GPU. The default value is 'no'. All default values\n"
        "      are for CPU mode.\n"
        "  --output <result_img>\n"
        "      The default is 'result.jpg'.\n";
}

//all input passed in via CVWrapper to stitcher function
int parseCmdArgs(int argc, char** argv)
{
    if (argc == 1)
    {
        printUsage();
        return -1;
    }
    for (int i = 1; i < argc; ++i)
    {
        if (string(argv[i]) == "--help" || string(argv[i]) == "/?")
        {
            printUsage();
            return -1;
        }
        else if (string(argv[i]) == "--try_use_gpu")
        {
            if (string(argv[i + 1]) == "no")
                try_use_gpu = false;
            else if (string(argv[i + 1]) == "yes")
                try_use_gpu = true;
            else
            {
                cout << "Bad --try_use_gpu flag value\n";
                return -1;
            }
            i++;
        }
        else if (string(argv[i]) == "--output")
        {
            result_name = argv[i + 1];
            i++;
        }
        else
        {
            Mat img = imread(argv[i]);
            if (img.empty())
            {
                cout << "Can't read image '" << argv[i] << "'\n";
                return -1;
            }
            imgs.push_back(img);
        }
    }
    return 0;
}


