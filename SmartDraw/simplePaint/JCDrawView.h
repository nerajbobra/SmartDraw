
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface JCDrawView : UIView

@property (nonatomic,retain) IBOutlet UIImageView *drawImageView;
@property (nonatomic,retain) UIColor *currentColor;

@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) CGPoint prePreviousPoint;
@property (nonatomic) CGPoint previousPoint;
@property (nonatomic) CGFloat lineWidth;

- (UIImage *)image;

@end
