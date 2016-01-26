# SmartDraw

This is the entire compilable project for the SmartDraw app:
https://itunes.apple.com/us/app/smartdraw/id979091740?mt=8

This project is essentially an OCR app for non-alphanumeric digits. It recognizes common shapes, including circle, diamond, heart, rectangle, triangle, smiley face (not a shape, but just for fun).

It also recognizes digits 0-9, to demonstrate the ability to do traditional OCR on top of shapes.

The algorithm follows the following steps:  
-binarize image  
-crop unused pixels into rectangular shape  
-apply anti-aliasing filter  
-resize image  
-apply guassian smoothing  
-calculate Histogram of Gradient (HoG) features  
-normalize features  
-apply multi-class SVM classifier (trained in MATLAB)  

Most of the image processing was implemented using OpenCV:  
http://opencv.org/

LIBSVM was used to train and classify:  
https://www.csie.ntu.edu.tw/~cjlin/libsvm/

To build the project, simply download and compile. There may be issues linking the opencv2.framework library. To fix this, go to
the Frameworks tab in the Navigator, and remove opencv2.framework. Then, under the SmartDraw target, scroll down to "Linked Frameworks and Libraries". Simply re-add opencv2.framework, and re-compile.
