

#import "JCViewController.h"
#import <opencv2/opencv.hpp>
#import "opencv2/highgui/ios.h"
#import "svm.h"
#import "HoG.h"
#include <stdlib.h>

@implementation JCViewController
@synthesize symbolButton;
@synthesize digitButton;
@synthesize classifyLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        ymax = 1.0;
        ymin = -1.0;
        
        [(JCDrawView*)[self view] setPreviousPoint:CGPointZero];
        [(JCDrawView*)[self view] setPrePreviousPoint:CGPointZero];
        [(JCDrawView*)[self view] setLineWidth:10.0];
        
        [self loadSVMmodel];
        
        //by default, initialize the app to "game mode"
        correctDrawing = 1;
        newDrawing = false;
        classifiedResult = -1;  //when the app just starts, this is -1
        currentShape = -1;
        
        objects = [NSArray arrayWithObjects:@"Circle",@"Diamond",@"Eight",@"Five",@"Four",@"Heart",@"Try again", @"Nine", @"One", @"Rectangle", @"Seven", @"Six", @"Smiley Face", @"Three", @"Triangle", @"Two", nil];
        
        NSLog(@"%i objects", [objects count]);
        
        //figure out the "junk class" index
        for (int i = 0; i < [objects count]; i++) {
            if ([@"Try again" isEqualToString:objects[i]]) {
                junkClassIndex = i;
                break;
            }
        }
        
        mode = 1;
        [self generateRandomShape];
        classifyLabel.text = [NSString stringWithFormat:@"Draw a %@\n ", objects[currentShape]];
        classifiedResult = -1;  //pretend like the app "just started"
        [self enableButtons];

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES;
    } else {
        return NO;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //clear the screen if this is a new image being drawn
    if (newDrawing) {
        [[(JCDrawView*)[self view] drawImageView] setImage:nil];
        newDrawing = false;
        
        //set the main label according to the mode
        if (mode == 0) {
            classifyLabel.text = @"";
        }
    }
    
    //if you touched it again within the timer period, then stop the timer
    [timer invalidate];
    timer = nil;
    
    //[self.exportButton setEnabled:YES];
    //NSLog(@"touches began!!");
}


- (void)generateRandomShape {
    
    //generate a random number between 0 and length(objects)-1, but skip the "junk" class. this is a hacky workaround
    //also, don't generate the current currentShape value
    firstRand = secondRand;
    secondRand = thirdRand;
    thirdRand = currentShape;
    while(currentShape == junkClassIndex || currentShape == firstRand || currentShape == secondRand || currentShape == thirdRand) {
        currentShape = arc4random_uniform([objects count]);
    }
    NSLog(@"Generated: %i", currentShape);
    
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //NSLog(@"touches ended!!");
    
    //start the timer when you lift your finger
    //set up the timer
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(doExport)
                                           userInfo:nil
                                            repeats:NO];
    
}

- (void) doExport {
    
    [self exportImage:self];
    
    newDrawing = true;
    
    if (mode == 0) {
        NSString *tempString;
        if ([@"Heart" isEqualToString:objects[classifiedResult]]) {
            tempString = @"♥";
        } else if ([@"Smiley Face" isEqualToString:objects[classifiedResult]]) {
            tempString = @"\U0001F60A";
        } else if ([@"Star" isEqualToString:objects[classifiedResult]]) {
            tempString = @"★";
        } else {
            tempString = objects[classifiedResult];
        }
        classifyLabel.text = [NSString stringWithFormat:@"%@!\n ", tempString];
    } else {
        if (classifiedResult == currentShape) {
            //generate a new random shape
            [self generateRandomShape];
            classifyLabel.text = [NSString stringWithFormat:@"Correct! Now draw a %@.\n ", objects[currentShape]];
        } else {
            if (classifiedResult != junkClassIndex) {
                classifyLabel.text = [NSString stringWithFormat:@"Oops, that's a %@.\nTry drawing a %@.", objects[classifiedResult], objects[currentShape]];
            } else {
                classifyLabel.text = [NSString stringWithFormat:@"Oops, that's not a %@.\nTry drawing a %@.", objects[currentShape], objects[currentShape]];
            }
        }

    }
}


#pragma mark - IBActions

- (IBAction)setBlackColor:(id)sender {
    [(JCDrawView*)[self view] setCurrentColor:[UIColor blackColor]];
}

- (IBAction)setRedColor:(id)sender {
    [(JCDrawView*)[self view] setCurrentColor:[UIColor redColor]];
}

- (IBAction)setGreenColor:(id)sender {
    [(JCDrawView*)[self view] setCurrentColor:[UIColor greenColor]];
}

- (IBAction)setBlueColor:(id)sender {
    [(JCDrawView*)[self view] setCurrentColor:[UIColor blueColor]];
}

- (IBAction)setWhiteColor:(id)sender {
    [(JCDrawView*)[self view] setCurrentColor:[UIColor whiteColor]];
}

- (IBAction)reset:(id)sender {
    [[(JCDrawView*)[self view] drawImageView] setImage:nil];
    [self.exportButton setEnabled:NO];
}

- (IBAction)setFreePlayMode:(id)sender {
    mode = 0;
    classifyLabel.text = @"";
    classifiedResult = -1;  //pretend like the app "just started"
    [[(JCDrawView*)[self view] drawImageView] setImage:nil];
    [self disableButtons];
}

- (IBAction)setGameMode:(id)sender {
    mode = 1;

    [self generateRandomShape];
    classifyLabel.text = [NSString stringWithFormat:@"Draw a %@\n ", objects[currentShape]];
    
    classifiedResult = -1;  //pretend like the app "just started"
    [[(JCDrawView*)[self view] drawImageView] setImage:nil];
    [self enableButtons];
}

- (IBAction)toggleDigits:(id)sender {
    if (mode == 1) {
        enableDigits  = 1; [digitButton setTintColor:self.view.tintColor];
        enableSymbols = 0; [symbolButton setTintColor:[UIColor lightGrayColor]];
        [self setGameMode:sender];
    }
}

- (IBAction)toggleSymbols:(id)sender {
    if (mode == 1) {
        enableDigits  = 0; [digitButton  setTintColor:[UIColor lightGrayColor]];
        enableSymbols = 1; [symbolButton setTintColor:self.view.tintColor];
        [self setGameMode:sender];
    }
}

-(IBAction)disableButtons {
    //Disable  mybtn. first set to gray
    [symbolButton setTintColor:[UIColor lightGrayColor]];
    [digitButton setTintColor:[UIColor lightGrayColor]];
    symbolButton.enabled = NO;
    digitButton.enabled = NO;
}

-(IBAction)enableButtons {
    //Disable  mybtn
    symbolButton.enabled = YES;
    digitButton.enabled = YES;
}


- (void)loadSVMmodel {
    
    //load the filepath
    NSString *temp;
    temp = [NSString stringWithFormat:@"model"];
    SVMpath = [[NSBundle mainBundle] pathForResource:temp ofType:@"model"];
    const char *SVMpathChar = [SVMpath UTF8String];
    SVMModel = svm_load_model(SVMpathChar);

    //load the normalization parameters
    NSString *path;
    NSString* data;
    NSArray *lines;
    int index = 0;
    
    //dump norm_params into matrix
    temp = [NSString stringWithFormat:@"norm_params"];
    path = [[NSBundle mainBundle] pathForResource:temp ofType:@"txt"];
    data = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: NULL];
    lines = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    index = 0;
    norm_params = cv::Mat([lines count]/2, 2, CV_32F);
    
    for (int i = 0; i < norm_params.rows; ++i) {
        for (int j = 0; j < norm_params.cols; ++j) {
            norm_params.at<float>(i, j) = [(NSNumber *)[lines objectAtIndex:index] floatValue];
            //NSLog(@"%f", norm_params.at<float>(i, j));
            index++;
        }
    }
    
    
    //load the columns to remove info
    index = 0;
    
    //dump cols_to_remove into matrix
    temp = [NSString stringWithFormat:@"cols_to_remove"];
    path = [[NSBundle mainBundle] pathForResource:temp ofType:@"txt"];
    data = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: NULL];
    lines = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    index = 0;
    cols_to_remove = cv::Mat([lines count]-1, 1, CV_32S);
    
    for (int i = 0; i < cols_to_remove.rows; ++i) {
        for (int j = 0; j < cols_to_remove.cols; ++j) {
            cols_to_remove.at<int>(i, j) = [(NSNumber *)[lines objectAtIndex:index] integerValue];
            //NSLog(@"%i", cols_to_remove.at<int>(i, j));
            index++;
        }
    }
    
    /*
    //load the PCA U matrix
    index = 0;
    
    //dump norm_params into matrix
    temp = [NSString stringWithFormat:@"PCA_U"];
    path = [[NSBundle mainBundle] pathForResource:temp ofType:@"txt"];
    data = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: NULL];
    lines = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    index = 0;
    PCA = cv::Mat(1157, 400, CV_32F);
    
    for (int i = 0; i < PCA.rows; ++i) {
        for (int j = 0; j < PCA.cols; ++j) {
            PCA.at<float>(i, j) = [(NSNumber *)[lines objectAtIndex:index] floatValue];
            //NSLog(@"%f", norm_params.at<float>(i, j));
            index++;
        }
    }
    */
    
    NSLog(@"Done loading weights from text files");
}

static int tapCount = 0;
- (IBAction)exportImage:(id)sender {
    //get a screenshot of the current screen
    UIImage *image = [(JCDrawView *)[self view] image];
    
    tapCount++;
    [self classify:image withCounter:tapCount];
}

- (void)image:(UIImage *)image didExportWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = @"Image successfully saved to Camera Roll";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    if (error) {
        message = [NSString stringWithFormat:@"Couldn't save image. %@", [error localizedDescription]];
        [alert setMessage:message];
        [alert setCancelButtonIndex:[alert addButtonWithTitle:@"Okay"]];
    } else {
        [alert setCancelButtonIndex:[alert addButtonWithTitle:@"Done"]];
    }
    
    [alert show];
    alert = nil;
}




- (void)classify:(UIImage *)img withCounter: (int)count {
    
#ifdef DEBUG
    
    //allocate a matrix for a single test example
    cv::Mat test_example = cv::Mat(1, X_test.cols, CV_32F);
    
    //loop through each test example
    int num_examples = X_test.rows;
    for (int k = 0; k < num_examples; k++) {
        
        //grab the first row
        X_test.row(k).copyTo(test_example.row(0));
        
        //loop through to verify the values
        for (int i = 0; i < test_example.cols; i++) {
            //NSLog(@"%f", test_example.at<float>(0, i));
        }
        
        double prob_est[NUM_CLASSIFIERS][2];  // Probability estimation
        for (int k = 0; k < NUM_CLASSIFIERS; k++) {
            struct svm_node *svmVec;
            svmVec = (struct svm_node *)malloc((test_example.cols+1)*sizeof(struct svm_node));
            double prob_est_temp[2];
            double *predictions = new double[test_example.rows];
            float *dataPtr = test_example.ptr<float>(); // Get data from OpenCV Mat
            int r, c;
            for (r=0; r<test_example.rows; r++)
            {
                for (c=0; c<test_example.cols; c++)
                {
                    svmVec[c].index = c+1;  // Index starts from 1; Pre-computed kernel starts from 0
                    svmVec[c].value = dataPtr[r*test_example.cols + c];
                }
                svmVec[c].index = -1;   // End of line
                
                if(svm_check_probability_model(SVMModel[k]))
                {
                    //get the prediction and put it in the matrix
                    predictions[r] = svm_predict_probability(SVMModel[k], svmVec, prob_est_temp);
                    
                    //TODO: this is a hack that subtracts 1 - probability for all the classifiers after the first one,
                    //but why is this necessary? figure this shit out
                    if (k == 0) {
                        prob_est[0][k] = prob_est_temp[0];
                        prob_est[1][k] = prob_est_temp[1];
                    } else {
                        prob_est[0][k] = 1 - prob_est_temp[0];
                        prob_est[1][k] = 1 - prob_est_temp[1];
                    }
                    
                    printf("%f\t%f\t%f\n", predictions[r], prob_est[0][k], prob_est[1][k]);
                }
                else
                {
                    predictions[r] = svm_predict(SVMModel[k], svmVec);
                    printf("%f\n", predictions[r]);
                }
            }
        }
        
    }
    
    return img;
    
#endif
    
    
    //CONVERT THE UIImage TO A GRAYSCALE CV MATRIX
    //For some reason this is being weird, it only works if you save the UIImage to disk and then re-load it
    // Create path.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.jpeg"];
    
    //Save image.
    [UIImageJPEGRepresentation(img, 1.0) writeToFile:filePath atomically:YES];
    
    std::string fileName = std::string([filePath UTF8String]);
    cv::Mat im_gray = cv::imread(fileName, CV_LOAD_IMAGE_GRAYSCALE);
    
    //convert to UInt8 for thresholding. normalize between 0 and 255
    cv::Mat im_gray_int;
    cv::normalize(im_gray, im_gray_int, 0, 255, CV_MINMAX, CV_8UC1);
    
    //CALCULATE THE BINARY IMAGE
    //using otsu's thresholding
    cv::Mat binImg;
    cv::threshold(im_gray_int, binImg, 0, 255, CV_THRESH_BINARY | CV_THRESH_OTSU);
    
    //INVERT THE IMAGE
    //for cropping purposes
    cv::Mat inverted;
    cv::bitwise_not(binImg, inverted);
    
    //crop the excess image as a rectangle. start by getting the edges of the shape
    int maxX = 1;
    int minX = inverted.cols;
    int maxY = 1;
    int minY = inverted.rows;
    
    bool searchMin = true;
    for (int i = 0; i < inverted.rows; i++) {
        for (int j = 0; j < inverted.cols; j++) {
            if ((searchMin) && ((int)inverted.at<uchar>(i,j) > 0)) {
                if (j < minX) {
                    minX = j;
                }
                
                if (i < minY) {
                    minY = i;
                }
                searchMin = false;
            }
            
            else if ((searchMin == false) && ((int)inverted.at<uchar>(i,j) > 0)) {
                if (j > maxX) {
                    maxX = j;
                }
                
                if (i > maxY) {
                    maxY = i;
                }
            }
        }
        searchMin = true;
    }
    
    //handle the case in which the user doesn't draw anything and tries to classify
    //also make sure the image is bigger than 5x5 pixels
    if ((maxX-minX < 5) || (maxY-minY < 5))  {
        NSLog(@"Nothing drawn...not doing anything");
        classifiedResult = junkClassIndex;
        return;
    }
    
    /*
     //set crop dimensions as a square
     //get height and width
     float height = maxY-minY;
     float width  = maxX-minX;
     
     //leave an extra p pixels on the edges
     float p = 5;
     
     //crop the excess image
     if (height > width) {
     //get the midpoint of width and define width to range +/- height/2
     float midpoint = (maxX+minX)/2;
     
     minX = round(midpoint-height/2) - p;
     maxX = round(midpoint+height/2) + p;
     
     minY = minY - p;
     maxY = maxY + p;
     
     //make sure the new boundaries are within the image dimensions
     if (minX < 0) { minX = 0; }
     if (maxX >= inverted.cols) { maxX = inverted.cols - 1; }
     
     if (minY < 0) { minY = 0; }
     if (maxY >= inverted.rows) { maxY = inverted.rows - 1; }
     
     
     } else {
     
     //get the midpoint of hight and define height to range +/- width/2
     float midpoint = (maxY+minY)/2;
     
     minY = round(midpoint-width/2) - p;
     maxY = round(midpoint+width/2) + p;
     
     minX = minX - p;
     maxX = maxX + p;
     
     //make sure the new boundaries are within the image dimensions
     if (minY < 0) { minY = 0; }
     if (maxY >= inverted.rows) { maxY = inverted.rows - 1; }
     
     if (minX < 0) { minX = 0; }
     if (maxX >= inverted.cols) { maxX = inverted.cols - 1; }
     
     }
     */
    //now actually crop the image (using the binary image)
    cv::Rect myROI(minX, minY, maxX-minX+1, maxY-minY+1);
    cv::Mat croppedRef = binImg(myROI);
    
    //Copy the data into new matrix
    cv::Mat cropped;
    croppedRef.copyTo(cropped);
    
    //convert the cropped image to a float
    cv::Mat croppedFloat;
    cropped.convertTo(croppedFloat, CV_32F);
    
    //apply anti-aliasing
    cv::Mat preSmoothed;
    cv::GaussianBlur(croppedFloat, preSmoothed, cv::Size(11,11), 0.8, 0.8, cv::BORDER_REPLICATE);
    
    //RESIZE THE IMAGE
    cv::Size size128(128,128);
    cv::Mat resized128;
    resize(preSmoothed,resized128,size128, 0, 0, cv::INTER_AREA); //resize image
    
    //apply gaussian smoothing
    cv::Mat smoothed;
    cv::GaussianBlur(resized128, smoothed, cv::Size(7,7), 0.3, 0.3, cv::BORDER_REPLICATE);
    
    /*
     for (int i = 0; i < smoothed.rows; ++i) {
     for (int j = 0; j < smoothed.cols; ++j) {
     NSLog(@"%f", smoothed.at<float>(i, j));
     }
     }
     */
    
    /*
     //deskew this bitch. algorithm 1
     cv::Moments moments = cv::moments(invertedFloat);
     cv::Mat deskewed;
     
     float m01 = moments.m01;
     float m10 = moments.m10;
     float m00 = moments.m00;
     
     float x_bar = m10/m00;
     float y_bar = m01/m00;
     
     float mu11 = moments.mu11;
     float mu20 = moments.mu20;
     float mu02 = moments.mu02;
     
     float lambda1 = 0.5*(mu20 + mu02) + 0.5*pow((pow(mu20,2) + pow(mu02,2) - 2*mu20*mu02 + 4*pow(mu11,2)),0.5);
     float lambda2 = 0.5*(mu20 + mu02) - 0.5*pow((pow(mu20,2) + pow(mu02,2) - 2*mu20*mu02 + 4*pow(mu11,2)),0.5);
     float lambda_m = fmax(lambda1, lambda2);
     
     //convert from radians to degrees
     float angle =  ceil(atan((lambda_m - mu20)/mu11)*18000/M_PI)/100;
     
     //calculate the rotation matrix
     cv::Point2f center(x_bar, y_bar);
     cv::Mat M = cv::getRotationMatrix2D(center, angle, 1.0);
     
     //warp the image
     cv::warpAffine(invertedFloat, deskewed, M, size128);
     
     UIImage *newImg = MatToUIImage(deskewed);
     return newImg;
     */
    
    
    /*
     //deskew this bitch. algorithm 2
     cv::Moments moments = cv::moments(resized16);
     cv::Mat deskewed;
     
     float mu11 = moments.mu11;
     float mu20 = moments.mu20;
     float mu02 = moments.mu02;
     
     //calculate the skew angle
     float theta = 0.5*atan((2*mu11)/(mu20-mu02));
     
     //define the transform matrix
     float M_float[2][3] = {{cos(theta), -sin(theta), 0}, {sin(theta), cos(theta), 0}};
     cv::Mat M = cv::Mat(2, 3, CV_32F, &M_float);
     
     //warp the image
     cv::warpAffine(resized16, deskewed, M, size16);
     */
    
    
    //resize to 16x16
    cv::Size size16(16,16);
    cv::Mat resized16;
    resize(smoothed,resized16,size16, 0, 0, cv::INTER_AREA);
    
    
    //convert to UInt8 for thresholding. normalize between 0 and 255
    cv::Mat resized16UInt8;
    cv::normalize(resized16, resized16UInt8, 0, 255, CV_MINMAX, CV_8UC1);
    
    //CALCULATE THE BINARY IMAGE
    //using otsu's thresholding
    cv::Mat binImg16;
    cv::threshold(resized16UInt8, binImg16, 0, 255, CV_THRESH_BINARY | CV_THRESH_OTSU);
    
    //back to float
    cv::Mat resized16float;
    binImg16.convertTo(resized16float, CV_32F);
    
    
    
    //GET THE HoG FEATURES
    
    //define the float arrays for the HoG results
    int HoG0_size = 224;
    int HoG1_size = 224;
    int HoG2_size = 504;
    int HoG3_size = 896;
    
    float HoG0[HoG0_size];
    float HoG1[HoG1_size];
    float HoG2[HoG2_size];
    float HoG3[HoG3_size];
    
    //parameter values
    float binSize = 14;
    float cellSize[4] = {6, 5, 4, 3};
    float blockSize = 2;
    float orientedGrads = 0;
    float clipVal = 0.2;
    
    //define parameter arrays
    float params0[5] = {binSize, cellSize[0], blockSize, orientedGrads, clipVal};
    float params1[5] = {binSize, cellSize[1], blockSize, orientedGrads, clipVal};
    float params2[5] = {binSize, cellSize[2], blockSize, orientedGrads, clipVal};
    float params3[5] = {binSize, cellSize[3], blockSize, orientedGrads, clipVal};
    
    //define options for HoG function
    int size[2] = {resized16float.rows, resized16float.cols};
    unsigned int grayscale = 1;                 //this is a grayscale image, NOT a color image
    
    //get the HoG features
    float *matData = (float*)resized16float.data;     //grab the float data from the mat
    HoG(matData, params0, size, HoG0, grayscale);
    HoG(matData, params1, size, HoG1, grayscale);
    HoG(matData, params2, size, HoG2, grayscale);
    HoG(matData, params3, size, HoG3, grayscale);
    
    //dump into mat files
    cv::Mat HoG0mat = cv::Mat(HoG0_size, 1, CV_32F, &HoG0);
    cv::Mat HoG1mat = cv::Mat(HoG1_size, 1, CV_32F, &HoG1);
    cv::Mat HoG2mat = cv::Mat(HoG2_size, 1, CV_32F, &HoG2);
    cv::Mat HoG3mat = cv::Mat(HoG3_size, 1, CV_32F, &HoG3);
    
    //concatenate into HoG0mat
    HoG0mat.push_back(HoG1mat);
    HoG0mat.push_back(HoG2mat);
    HoG0mat.push_back(HoG3mat);
    
    //transpose to 1 x 1008
    cv::Mat reshapedCol;
    cv::transpose(HoG0mat, reshapedCol);

    NSLog(@"numrows: %i, numcols: %i", reshapedCol.rows, reshapedCol.cols);
    
    //[self saveFloatToText:reshapedCol];
    
    //set the columns to be removed as NaN values
    for (int i = 0; i < cols_to_remove.rows; i++) {
        //NSLog(@"%i",cols_to_remove.at<int>(i,0));
        reshapedCol.at<float>(0, cols_to_remove.at<int>(i,0)) = NAN;
    }
    
    //create a new row array without the NaN values
    cv::Mat const_cols_removed;
    for (int i = 0; i < reshapedCol.cols; i++) {
        if (!isnan(reshapedCol.at<float>(0, i))) {
            const_cols_removed.push_back(reshapedCol.at<float>(0,i));
        }
    }
    
    //transpose to column array
    cv::Mat const_cols_removed_transposed;
    cv::transpose(const_cols_removed, const_cols_removed_transposed);
    
    //normalize the features
    cv::Mat prePCA;
    prePCA = [self normalizeFeaturesMeanStd:const_cols_removed_transposed];
    
    //apply PCA dimension reduction
    cv::Mat normalized;
    //normalized = prePCA*PCA;  //NOT DOING THIS ANYMORE
    normalized = prePCA;
    
    struct svm_node *svmVec;
    svmVec = (struct svm_node *)malloc((normalized.cols+1)*sizeof(struct svm_node));
    double *predictions = new double[normalized.rows];
    float *dataPtr = normalized.ptr<float>(); // Get data from OpenCV Mat
    double prob_est[NUM_CLASSIFIERS];  // Probability estimation
    int r, c;
    for (r=0; r<normalized.rows; r++)
    {
        for (c=0; c<normalized.cols; c++)
        {
            svmVec[c].index = c+1;  // Index starts from 1; Pre-computed kernel starts from 0
            svmVec[c].value = dataPtr[r*normalized.cols + c];
        }
        svmVec[c].index = -1;   // End of line
        
        if(svm_check_probability_model(SVMModel))
        {
            predictions[r] = svm_predict_probability(SVMModel, svmVec, prob_est);
            printf("%f\t%f\t%f\n", predictions[r], prob_est[0], prob_est[1]);
        }
        else
        {
            predictions[r] = svm_predict(SVMModel, svmVec);
            printf("%f\n", predictions[r]);
        }
    }
    
    
    //TODO: de alloc svmVec?
    free(svmVec);
    
    //figure out which one was the biggest
    int maxIndex = 0;
    float maxProb = 0;
    for (int k = 0; k < NUM_CLASSIFIERS; k++) {
        if (prob_est[k] > maxProb) {
            maxProb = prob_est[k];
            maxIndex = k;
        }
    }
    
    NSLog(@"class: %i, max prob: %f", maxIndex, maxProb);
    
    if (maxProb > 0.55) {
        classifiedResult = maxIndex;
    } else {
        classifiedResult = junkClassIndex;
    }
    
    NSLog(@"Done classifying");
    //classifyLabel.text = result;
    
    /*
    //convert the gaussian image back to a UIImage for display purposes
    UIImage *newImg = MatToUIImage(resized128);
    
    //get the documents directory:
    paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSLog(@"tapCount: %i", tapCount);
    NSLog(@"NUM_CLASSIFERS: %i", NUM_CLASSIFIERS);
    NSString *newFileName = [NSString stringWithFormat:@"%@/%d.jpeg", documentsDirectory, tapCount];
    //[UIImageJPEGRepresentation(newImg, 1.0) writeToFile:newFileName atomically:YES];
    
    //also save the original image
    newFileName = [NSString stringWithFormat:@"%@/%d_orig.jpeg", documentsDirectory, tapCount];
    //[UIImageJPEGRepresentation(img, 1.0) writeToFile:newFileName atomically:YES];
    */
    

    return;
    
}


- (cv::Mat)normalizeFeaturesMeanStd:(cv::Mat) X {
    
    cv::Mat X_normalized(1, X.cols, CV_32F);
    
    //loop through each column and normalize
    float temp = 0;
    for (int i = 0; i < X.cols; i++) {
        temp = X.at<float>(0, i);
        //NSLog(@"%f", temp);
        
        mu = norm_params.at<float>(i, 0);
        sigma = norm_params.at<float>(i, 1);
        
        temp = (temp - mu)/sigma;
        
        //NSLog(@"%f, %f", mu, sigma);
        
        X_normalized.at<float>(0, i) = temp;
        //NSLog(@"%f", temp);
        
    }
    
    NSLog(@"done normalizing");
    
    return X_normalized;
}


- (cv::Mat)normalizeFeaturesMinMax:(cv::Mat) X {
    
    cv::Mat X_normalized(1, X.cols, CV_32F);
    
    //loop through each row and normalize
    float temp = 0;
    for (int i = 0; i < X.cols; i++) {
        temp = X.at<float>(0, i);
        //NSLog(@"%f", temp);
        
        //check to see if xmax-xmin = 0
        xmin = norm_params.at<float>(i, 0);
        xmax = norm_params.at<float>(i, 1);
        
        //NSLog(@"%f, %d", xmin - xmax, round(xmin - xmax) == 0);
        
        //don't change anything if it's zero
        if (round(xmin - xmax) == 0) {
            //NSLog(@"divide by zero");
            continue;
        }
        temp = (ymax-ymin)*(temp-xmin)/(xmax-xmin) + ymin;
        X_normalized.at<float>(0, i) = temp;
        //NSLog(@"%f", temp);
        
    }
    
    NSLog(@"done normalizing");
    
    return X_normalized;
}


- (void)saveFloatToText:(cv::Mat) mat {
    
    //copy over the values into an array
    NSMutableString *array = [[NSMutableString alloc] initWithCapacity:mat.rows * mat.cols];
    for (int i = 0; i < mat.rows; ++i) {
        for (int j = 0; j < mat.cols; ++j) {
            //NSLog(@"%f", mat.at<float>(i,j));
            [array appendString:[NSString stringWithFormat:@"%f\n",(float)mat.at<float>(i,j)]];
            
        }
    }
    
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileNameNew = [NSString stringWithFormat:@"%@/%i.txt", documentsDirectory, tapCount];
    
    //save the image as a 1D vector in a text file
    [array writeToFile:fileNameNew atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
}

- (void)saveUIntToText:(cv::Mat) mat {
    
    //copy over the values into an array
    NSMutableString *array = [[NSMutableString alloc] initWithCapacity:mat.rows * mat.cols];
    for (int i = 0; i < mat.rows; ++i) {
        for (int j = 0; j < mat.cols; ++j) {
            //NSLog(@"%f", mat.at<float>(i,j));
            [array appendString:[NSString stringWithFormat:@"%i\n",(UInt8)mat.at<UInt8>(i,j)]];
            
        }
    }
    
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileNameNew = [NSString stringWithFormat:@"%@/%i.txt", documentsDirectory, tapCount];
    
    //save the image as a 1D vector in a text file
    [array writeToFile:fileNameNew atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
}


- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}




@end
