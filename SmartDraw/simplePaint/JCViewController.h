

/*
 
 VALUES TO MANUALLY DEFINE:
 -NUM_CLASSIFIERS
 -PCA matrix size
 -HOG matrix size
 
 */




#import <UIKit/UIKit.h>
#import "JCDrawView.h"

#define NUM_CLASSIFIERS 16

#ifdef DEBUG
#undef DEBUG
#endif
//#define DEBUG 1

@interface JCViewController : UIViewController {
    //global variables
    cv::Mat norm_params;
    cv::Mat cols_to_remove;
    cv::Mat PCA;
    cv::Mat X_test;
    
    float ymax;
    float ymin;
    float xmax;
    float xmin;
    float mu;
    float sigma;
    
    struct svm_model *SVMModel;

    NSString *SVMpath;
    
    //parameters for HoG
    float params[3][5];
    
    NSTimer *timer;
    
    bool newDrawing;
    
    //free mode = 0, game mode = 1
    //correct drawing only is valid during game mode
    int mode;
    int classifiedResult;
    int correctDrawing;
    
    //holds an array of NSString's with the name of each object
    NSArray *objects;
    int currentShape;   //the index corresponding to the current shape in the objects array
    int junkClassIndex;      //index of the "try again..." class
    
    //values to keep track of whether digits or objects are enabled
    int enableDigits;
    int enableSymbols;
    NSArray *digitIndices;
    NSArray *symbolIndices;
    
    //make sure we dont repeat the same "random" number as the last 3 values
    int firstRand;
    int secondRand;
    int thirdRand;
    
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *exportButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *symbolButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *digitButton;
@property (nonatomic, retain) IBOutlet UILabel *classifyLabel;

- (IBAction)toggleSymbols:(id)sender;
- (IBAction)toggleDigits:(id)sender;

- (IBAction)setFreePlayMode:(id)sender;
- (IBAction)setGameMode:(id)sender;

- (IBAction)reset:(id)sender;
- (IBAction)exportImage:(id)sender;

@end


