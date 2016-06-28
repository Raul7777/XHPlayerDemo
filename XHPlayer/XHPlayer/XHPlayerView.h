
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "XHPlayerViewTopView.h"
#import "XHPlayerViewBottomView.h"

typedef enum : NSInteger{
    PanDirectionNone,
    PanDirectionUp,
    PanDirectionDown,
    PanDirectionRight,
    PanDirectionLeft
} PanDirection;


@protocol XHPlayerViewDelegate <NSObject>
- (void)playerViewDidClickBackButton;
- (void)playViewDidDoubleTap;
- (void)playViewDidSwipeOver:(NSInteger)seconds;
- (void)playViewDidChangeVolume:(CGFloat)volume;
@end


@class XHPlayer;
@interface XHPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) XHPlayer *playerContainer;

@property (nonatomic, copy) NSString *videoFillMode;

- (void)showIndicator;
- (void)hideIndicator;
@property (nonatomic, weak) XHPlayerViewTopView *topView;
@property (nonatomic, weak) XHPlayerViewBottomView *bottomView;

@property (nonatomic, weak) id <XHPlayerViewDelegate> delegate;


@property (nonatomic, assign) UIDeviceOrientation orientation;

@property (nonatomic, assign) PanDirection  direction;

/**
 *  如果从左滑倒右,快进/快退的时间,默认90s,根据widthSeconds/width计算划过屏幕尺寸快进的时间
 */
@property (nonatomic, assign) CGFloat widthSeconds;
@end
