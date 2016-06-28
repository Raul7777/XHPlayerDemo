

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  Playback State
 */
typedef NS_ENUM(NSInteger, PlayerPlaybackState) {
    /**
     *  Player Stop
     */
    PlayerPlaybackStateStopped = 0,
    /**
     *  Player Playing
     */
    PlayerPlaybackStatePlaying,
    /**
     *  Player Pause
     */
    PlayerPlaybackStatePaused,
    /**
     *  Player Failed
     */
    PlayerPlaybackStateFailed,
};
/**
 *  Buffering State
 */
typedef NS_ENUM(NSInteger, PlayerBufferingState) {
    /**
     *  Buffering
     */
    PlayerBufferingStateBuffering = 0,
    /**
     *  Buffering keepUp
     */
    PlayerBufferingStateKeepUp,
    /**
     *  Delayed buffering
     */
    PlayerBufferingStateDelayed,
    /**
     *  Buffer Full
     */
    PlayerBufferingStateFull,
    /**
     *  Up to grade
     */
    PlayerBufferingStateUpToGrade,
};

@class XHPlayer;

@protocol XHPlayerDelegate <NSObject>

// 播放完成
- (void)playerPlaybackDidEnd:(XHPlayer *)player;
/**
 *  播放状态发发生改变
 *
 *  @param player player
 *  @param state  播放状态
 */
- (void)player:(XHPlayer *)player playStateChanged:(PlayerPlaybackState)state;
/**
 *  监听屏幕方向的改变
 *
 *  @param player      player
 *  @param orientation 屏幕方向
 */
- (void)player:(XHPlayer *)player orientationChanged:(UIDeviceOrientation)orientation;
@end


@interface XHPlayer : UIView

/**
 *  根据frame 初始化一个播放器
 *
 *  @param frame       frame
 *  @param videoURLStr 地址
 */
- (instancetype)initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr;

@property (nonatomic, weak) id <XHPlayerDelegate> delegate;

/**
 *  Media playback state
 */
@property (nonatomic, assign) PlayerPlaybackState playbackState;

/**
 * 播放完成后是否要进行从头播放,默认为no
 */
@property (nonatomic, assign) BOOL playbackLoops;

#pragma mark - 可以通过改变下面三个任意一个改变播放器地址
/**
 *  播放地址
 */
@property (nonatomic, copy) NSString *mediaPath;
@property (nonatomic, strong) AVAsset *mediaAsset;
@property (nonatomic, strong) AVPlayerItem *playerItem;

#pragma mark - 是否自动全屏
/**
 *  yes 不用手动去设置全屏的方法,no 需要用户自己去实现全屏的代码,默认是yes
 *  如果要手动实现全屏的代码,实现代理方法即可
 */
@property (nonatomic, assign) BOOL isAutoFullScreen;

/** 初始时所在的父控件 */
/** 全屏 是将player 添加到window上,当要退出全屏,要将player重新添回到初始的父控件中 */
@property (nonatomic, weak) UIView *firstSuperView;

#pragma mark - customMethod
/**
 *  当要退出控制器,或者要移除播放器的时候要调用这个方法
 */
- (void)close;

- (void)play;
- (void)pause;
/** 播放器的标题 */
@property (nonatomic, copy) NSString *title;
@end
