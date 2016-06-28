

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "XHPlayerProgressView.h"
@class XHPlayerViewBottomView;
@protocol XHPlayerViewBottomViewDelegate <NSObject>

@optional
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didClcikControlButton:(UIButton *)controlButton;
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didClcikFullScreenButton:(UIButton *)FullScreenButton;
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didUpdateProgressView:(XHPlayerProgressView *)progressView;
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView sliderPositionSliderUp:(XHPlayerProgressView *)progressView;
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView sliderPositionSliderDown:(XHPlayerProgressView *)progressView;

@end

@interface XHPlayerViewBottomView : UIView
/**
 *  当前时间
 */
@property (nonatomic, weak) UILabel *currentTimeLabel;
/**
 *  总时间
 */
@property (nonatomic, weak) UILabel *totalTimeLabel;
/**
 *  控制button
 */
@property (nonatomic, weak) UIButton *controlButton;

/**
 *  全屏 button
 */
@property (nonatomic, weak) UIButton *fullScreenButton;
/**
 *  进度条
 */
@property (nonatomic, weak) XHPlayerProgressView *progressView;

@property (nonatomic, weak) id <XHPlayerViewBottomViewDelegate> delegate;

- (void)updatePlayingTime:(CGFloat)readDuration;
- (void)updateTotalTime:(CGFloat)taotalDuration;
- (void)updateBufferringTime:(CMTime)bufferDuration;
@end
