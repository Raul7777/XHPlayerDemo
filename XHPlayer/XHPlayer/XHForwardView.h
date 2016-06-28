
#import <UIKit/UIKit.h>

typedef enum {
    XHForwardViewModeForward,
    XHForwardViewModeRewind
}XHForwardViewMode;

@interface XHForwardView : UIView
@property (nonatomic, weak) UILabel *timeLabel;

@property (nonatomic, assign) XHForwardViewMode mode;
@end
