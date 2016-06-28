
#import "XHPlayer.h"
#import "XHPlayerView.h"
#import "Masonry.h"

#define screenW [UIScreen mainScreen].bounds.size.width
#define screenH [UIScreen mainScreen].bounds.size.height

// Player Item Load Keys
static NSString * const XHPlayerTracksKey = @"tracks";
static NSString * const XHPlayerPlayableKey = @"playable";
static NSString * const XHPlayerDurationKey = @"duration";


// KVO Player Keys
static NSString * const XHPlayerRateKey = @"rate";  // rate
// KVO Player Item Keys
static NSString * const XHPlayerStatusKey = @"status"; // 状态
static NSString * const XHPlayerEmptyBufferKey = @"playbackBufferEmpty"; // 缓冲操作
static NSString * const XHPlayerPlayerKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const XHPlayerPlayerBufferFullKey = @"playbackBufferFull";
// KVO Player Preload Keys
static NSString * const XHPlayerPlayerLoadedTimeRanges = @"loadedTimeRanges";  // 缓冲进度

// KVO Contexts
static NSString * const XHPlayerObserverContext = @"XHPlayerObserverContext";
static NSString * const XHPlayerItemObserverContext = @"XHPlayerItemObserverContext";
static NSString * const XHPlayerPreloadObserverContext = @"XHPlayerPreloadObserverContext";


@interface XHPlayer ()<XHPlayerViewBottomViewDelegate,XHPlayerViewDelegate>
{
@private
    
    id _playbackTimeObserver;
    
    BOOL _userPause; // 标识是不是用户手动暂停,还是由于网络卡顿等造成的自动暂停
}



/**
 *  player
 */
@property (nonatomic, strong) AVPlayer *player;
/**
 *  播放器的view 提供各种操作
 */
@property (nonatomic, weak) XHPlayerView *playerView;

/**
 *  标识 用于判断是否在拖动进度条
 */
@property (nonatomic, assign) BOOL isDragingSlider;

/**
 *  总时间
 */
@property (nonatomic, assign) CMTime totalDuration;
/**
 *  当前时间
 */
@property (nonatomic, assign) CMTime readDuration;
/**
 *  缓冲时间
 */
@property (nonatomic, assign) CMTime bufferDuration;


@property (nonatomic, assign) UIDeviceOrientation orientation;
@property (nonatomic, assign) BOOL isFullScreen;

// 初始状态下的frame
@property (nonatomic, assign) CGRect origianlFrame;

@property (nonatomic, assign,readonly) PlayerBufferingState bufferingState;

@end


@implementation XHPlayer
#pragma mark - 初始化操作

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {

        [self setUp];
        self.backgroundColor = [UIColor blackColor];
      
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr{
    if (self = [super init]) {
        self.mediaPath = videoURLStr;
    }
    return self;
}

#pragma mark - Setup Methods
- (void)setUp{
    
    self.isAutoFullScreen = YES;
    
    // 初始化一个播放器
    [self setupPlayer];
    
    // 初始化playerView
    [self setupPlayerView];
    
    // 加载数据
    [self loadMediaData];
    
    
    // 添加对屏幕旋转事件的监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification"object:nil];
}
/**
 *  初始化播放器
 */
- (void)setupPlayer {
    self.player = [[AVPlayer alloc] init];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    // Player KVO
    [self addObserverWithPlayer:self.player];
}
/**
 *  初始化 播放器 view
 */
- (void)setupPlayerView {
    // load the playerLayer view
    if (!_playerView) {
        XHPlayerView *playerView = [[XHPlayerView alloc] init];
        playerView.delegate = self;
        playerView.bottomView.delegate = self;
        [self setPlayerView:playerView];
    }
}
- (void)setPlayerView:(XHPlayerView *)playerView {
    if (_playerView) {
        [_playerView removeFromSuperview];
        _playerView = nil;
    }
    _playerView = playerView;
    if (_playerView) {
        [self addSubview:playerView];
        // 设置约束条件
        [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.bottom.left.equalTo(self);
        }];
        
        if ([playerView respondsToSelector:@selector(playerContainer)]) {
            playerView.playerContainer = self; // 赋值操作
        }
        playerView.player = self.player;
        
    }
}

// 加载数据
- (void)loadMediaData {
    if (!self.mediaAsset) {
        return;
    }
    [self showIndicator];  // 展示加载indicator
    
    NSArray *keys = @[XHPlayerTracksKey,
                      XHPlayerPlayableKey,
                      XHPlayerDurationKey];
    
    __weak typeof(self.mediaAsset) weakAsset = self.mediaAsset;
    __weak typeof(self) weakSelf = self;
    
    // 异步加载数据,防止阻塞主线程
    [self.mediaAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // check the keys
            for (NSString *key in keys) {
                NSError *error = nil;
                AVKeyValueStatus keyStatus = [weakAsset statusOfValueForKey:key error:&error];
                if (keyStatus == AVKeyValueStatusFailed) {
                    [weakSelf callBackDelegateWithPlaybackState:PlayerPlaybackStateFailed]; // 加载失败
                    NSLog(@"error (%@)", [[error userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey]);
                    return;
                }
            }
            
            // check playable
            if (!weakAsset.playable) { // 不能播放
                [weakSelf callBackDelegateWithPlaybackState:PlayerPlaybackStateFailed];
                return;
            }
            
            // setup player
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:weakAsset];
            [weakSelf setPlayerItem:playerItem];
        });
    }];
}

#pragma mark - setter 方法

- (void)setTitle:(NSString *)title{
    _title = title;
    self.playerView.topView.title = title;
}

- (void)setMediaPath:(NSString *)mediaPath {
    if (_mediaPath == mediaPath) { // 如果路径相同 不做任何操作
        return;
    }
    if (!mediaPath || !mediaPath.length) {
        _mediaPath = nil;
        [self setMediaAsset:nil];
        return;
    }
    _mediaPath = [mediaPath copy];
    [self updateMediaAssetWithMediaPath:_mediaPath];
}

- (void)updateMediaAssetWithMediaPath:(NSString *)mediaPath {
    NSURL *mediaURL = [NSURL URLWithString:mediaPath];
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:mediaURL options:nil];
    [self setMediaAsset:urlAsset];
}

- (void)setMediaAsset:(AVAsset *)mediaAsset {
    if (_mediaAsset == mediaAsset) {
        return;
    }
    
    //    // 判断是否在播放，如果在播放，需要先暂停一下
    if (self.playbackState == PlayerPlaybackStatePlaying && _mediaAsset) {
        [self stop];
    }
    self.bufferingState = PlayerBufferingStateBuffering;
    _mediaAsset = mediaAsset;
    
    // 如果没有媒体资源文件，那就置空PlayerItem
    if (!_mediaAsset) {
        [self setPlayerItem:nil];
    }else{
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:_mediaAsset];
        [self setPlayerItem:item];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem{
    if (_playerItem == playerItem) {
        return;
    }
    
    if (_playerItem) { // 移除监听
        // Remove KVO
        [self removeObserverWithPlayerItem:_playerItem];
        [self removeNotificationWithPlayerItem:_playerItem];
        [_playerItem cancelPendingSeeks];
        _playerItem = nil;
    }
    
    _playerItem = playerItem;
    // 再次确认不是为空的
    if (playerItem) {
        // Add KVO and Notification
        [self addObserverWithPlayerItem:playerItem];
        // 添加通知对象
        [self addNotificationWithPlayerItem:playerItem];
        
    }
    
    if (!self.playbackLoops) {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    } else {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
    
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}



- (void)setBufferingState:(PlayerBufferingState)bufferingState{
    _bufferingState = bufferingState;
    switch (bufferingState) {
        case PlayerBufferingStateBuffering:
        case PlayerBufferingStateDelayed: {
            // 判断现在是否有网络，如果没有网络就需要通知缓冲停止了
            if (self.bufferingState != PlayerBufferingStateFull ) {
                [self showIndicator];
            }
            break;
        }
            // 隐藏缓冲加载提示
        case PlayerBufferingStateFull:
        case PlayerBufferingStateUpToGrade: {
            [self hideIndicator];
            break;
        }
        case PlayerBufferingStateKeepUp:{
            if (!_userPause ) {
                
                [self.player play];
                [self hideIndicator];
            }
            break;
        }
            
        default:
            break;
    }
    
}

- (void)setOrientation:(UIDeviceOrientation)orientation{
    _orientation = orientation;
    
    self.playerView.orientation = orientation;
    
    if (self.isAutoFullScreen) {
        
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) { // 切换到全屏
            
            [self removeFromSuperview];
            
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            if (!keyWindow) {
                keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
            }
            [keyWindow addSubview:self];
            
            
            if (CGRectEqualToRect(self.origianlFrame, CGRectZero)) {
                
                self.origianlFrame = self.frame;
            }
            if (self.isFullScreen) {
                return;
            }else{
                self.frame = CGRectMake(0, 0, screenW, screenH);
            }
        }
        if (orientation == UIDeviceOrientationPortrait) {
            [self removeFromSuperview];
            [self.firstSuperView addSubview:self];
            self.isFullScreen = NO;
            self.frame = self.origianlFrame;
            
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(player:orientationChanged:)]) {
            [self.delegate player:self orientationChanged:orientation];
        }
    }
    
}


#pragma mark - AVFoundation Handle NSNotificaion Methods
/**
 *  播放到最后
 *
 */
- (void)playerItemDidPlayToEndTime:(NSNotification *)notification {
    if (!self.playbackLoops) {
        [self stop];
        [self callBackDelegateWithPlaybackDidEnd];
    } else {
        [self.player seekToTime:kCMTimeZero];
    }
}
/**
 *  failed
 */
- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [self callBackDelegateWithPlaybackState:PlayerPlaybackStateFailed];
}

#pragma mark - 一些回调方法

/**
 *  更新缓冲进度
 *
 *  @param timeRanges 缓冲进度
 */

- (void)updateLoadedTimeRanges:(NSArray *)timeRanges {
    if (timeRanges && [timeRanges count]) {
        CMTimeRange timerange = [[timeRanges firstObject] CMTimeRangeValue];
        CMTime bufferDuration = CMTimeAdd(timerange.start, timerange.duration);
        // 更新缓冲进度条
        [self callBackDelegateWithDidChangeBufferDuration:bufferDuration];
    }
}

/**
 *  播放状态改变的回调函数
 *
 */
- (void)callBackDelegateWithPlaybackState:(PlayerPlaybackState)playbackState {
    self.playbackState = playbackState;
    if ([self.delegate respondsToSelector:@selector(player:playStateChanged:)]) {
        [self.delegate player:self playStateChanged:playbackState];
    }
}

/**
 *  结束
 */
- (void)callBackDelegateWithPlaybackDidEnd {
    if ([self.delegate respondsToSelector:@selector(playerPlaybackDidEnd:)]) {
        [self.delegate playerPlaybackDidEnd:self];
    }
}
/**
 *  更新当前时间和进度条
 *
 *  @param readDuration 当前时间
 */
- (void)callBackDelegateWithDidChangeReadDuration:(CMTime)readDuration {
    self.readDuration = readDuration;
    // 更新bottomView控件
    double time = CMTimeGetSeconds([self.player currentTime]);
    if ([self.playerView.bottomView respondsToSelector:@selector(updatePlayingTime:)]) {
        [self.playerView.bottomView  updatePlayingTime:time / CMTimeGetSeconds(self.totalDuration)];
    }
}
/**
 *  更新总时间
 *
 *  @param duration 总时间
 */
- (void)callBackDelegateWithDidChangeTotalTime:(CMTime)duration{
    self.totalDuration = duration;
    if ([self.playerView.bottomView  respondsToSelector:@selector(updateTotalTime:)]) {
        [self.playerView.bottomView  updateTotalTime:CMTimeGetSeconds(duration)];
    }
}
/**
 *  更新缓冲进度条
 *
 *  @param bufferDuration 缓冲进度
 */
- (void)callBackDelegateWithDidChangeBufferDuration:(CMTime)bufferDuration{
    self.bufferDuration = bufferDuration;
    if ([self.playerView.bottomView  respondsToSelector:@selector(updateBufferringTime:)]) {
        [self.playerView.bottomView  updateBufferringTime:bufferDuration];
    }
}

#pragma mark - playerView 代理方法

- (void)playerViewDidClickBackButton{
    if (self.orientation == UIDeviceOrientationLandscapeLeft || self.orientation == UIDeviceOrientationLandscapeRight) {
        [self playerViewBottomView:self.playerView.bottomView didClcikFullScreenButton:self.playerView.bottomView.fullScreenButton];
    }
}
- (void)playViewDidDoubleTap{
    [self playerControl];
}

- (void)playerControl {
    if (self.mediaPath || self.mediaAsset) {
        switch (self.playbackState) {
            case PlayerPlaybackStateStopped: {
                [self playBeginning];
                break;
            }
            case PlayerPlaybackStatePaused: {
                [self playCurrentTime];
                break;
            }
            case PlayerPlaybackStatePlaying:
            case PlayerPlaybackStateFailed:
            default: {
                [self pause];
                break;
            }
        }
    }
}

#pragma mark - playView 和subView的Delegate
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didClcikControlButton:(UIButton *)controlButton{
    if (controlButton.selected) {
        [self pause];
    }else{
        [self play];
    }
    controlButton.selected = !controlButton.selected;
}
- (void)playViewDidChangeVolume:(CGFloat)volume{
    self.player.volume += volume;
    NSLog(@"%F",self.player.volume);
}
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didClcikFullScreenButton:(UIButton *)FullScreenButton{
    if (FullScreenButton.selected) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationPortrait;
            
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }else{
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationLandscapeRight;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
        
    }
    
}
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView didUpdateProgressView:(XHPlayerProgressView *)progressView{
    self.isDragingSlider = YES;
}
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView sliderPositionSliderUp:(XHPlayerProgressView *)progressView{
    
    self.isDragingSlider = NO;
    [self.player seekToTime:CMTimeMakeWithSeconds(progressView.value *self.totalDuration.value/ self.totalDuration.timescale , 1)];
}
- (void)playerViewBottomView:(XHPlayerViewBottomView *)bottomView sliderPositionSliderDown:(XHPlayerProgressView *)progressView{
    self.isDragingSlider = YES;
}
- (void)playViewDidSwipeOver:(NSInteger)seconds{
    
    CMTime currentTime = self.player.currentTime;
    
    [self.player seekToTime:CMTimeMake(currentTime.value/currentTime.timescale + seconds, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
/**
 *  移除监听
 */
- (void)removeNotification {
    // notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma  mark - observer 操作

/**
 *  对playerItem 添加监听
 *
 */
- (void)addNotificationWithPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
}
/**
 *  移除 playerItem监听
 *
 */
- (void)removeNotificationWithPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
}

#pragma mark - KVO 监听
- (void)addObserverWithPlayer:(AVPlayer *)player {
    
        [player addObserver:self forKeyPath:XHPlayerRateKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)XHPlayerObserverContext];
    // Player Observer
    __weak __typeof(self) weakSelf = self;
    _playbackTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f) queue:NULL usingBlock:^(CMTime time) {
        if (!weakSelf.isDragingSlider) { // 如果用户没有拖动进度条 更新时间
            [weakSelf callBackDelegateWithDidChangeReadDuration:time];
        }
    }];
}

// 移除对player的监听
- (void)removeObserverWithPlayer:(AVPlayer *)player {
        [player removeObserver:self forKeyPath:XHPlayerRateKey context:(__bridge void *)XHPlayerObserverContext];
    [player removeTimeObserver:_playbackTimeObserver];
}


/**
 *  对playerItem移除监听
 */
- (void)removeObserverWithPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:XHPlayerEmptyBufferKey context:(__bridge void *)XHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:XHPlayerPlayerKeepUpKey context:(__bridge void *)XHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:XHPlayerPlayerBufferFullKey context:(__bridge void *)XHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:XHPlayerStatusKey context:(__bridge void *)XHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:XHPlayerPlayerLoadedTimeRanges context:(__bridge void *)XHPlayerPreloadObserverContext];
}

/**
 *  添加监听
 */
- (void)addObserverWithPlayerItem:(AVPlayerItem *)playerItem {
    
    
    [playerItem addObserver:self forKeyPath:XHPlayerStatusKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(XHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:XHPlayerPlayerLoadedTimeRanges options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(XHPlayerPreloadObserverContext)];
    [playerItem addObserver:self forKeyPath:XHPlayerEmptyBufferKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(XHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:XHPlayerPlayerKeepUpKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(XHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:XHPlayerPlayerBufferFullKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(XHPlayerItemObserverContext)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if (!_player || !_playerItem) {
        return;
    }
    if (context == (__bridge void *)(XHPlayerObserverContext)) {
        // Player KVO
        if ([keyPath isEqualToString:XHPlayerRateKey]) {
            float rate = [change[NSKeyValueChangeNewKey] floatValue];
            if (rate) {
                _playbackState = PlayerPlaybackStatePlaying; // 获取播放的状态
            } else {
                _playbackState = PlayerPlaybackStatePaused; // 获取播放状态
            }
        }
    } else if (context == (__bridge void *)(XHPlayerItemObserverContext)) {
        // PlayerItem KVO
        if ([keyPath isEqualToString:XHPlayerEmptyBufferKey]) {
            if (self.playerItem.playbackBufferEmpty) {
                _userPause = NO;
                self.bufferingState = PlayerBufferingStateDelayed;
            }
        } else if ([keyPath isEqualToString:XHPlayerPlayerKeepUpKey]) {
            if (self.playerItem.playbackLikelyToKeepUp) {
             
                self.bufferingState = PlayerBufferingStateKeepUp;
            }
        } else if ([keyPath isEqualToString:XHPlayerPlayerBufferFullKey]) {
            if (self.playerItem.playbackBufferFull) {
                self.bufferingState = PlayerBufferingStateFull;
            }
        }else if ([keyPath isEqualToString:XHPlayerStatusKey]) {
            AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerStatusReadyToPlay: { // 准备好播放
                    [self.player play];
                    AVPlayerItem *playerItem = (AVPlayerItem *)object;
                    self.totalDuration = playerItem.duration;// 转换成播放时间
                    [self callBackDelegateWithDidChangeTotalTime:playerItem.duration];
                    break;
                }
                case AVPlayerStatusFailed: { // 失败 弹窗
                    //                    _flags.readPlayer = NO;
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:nil delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
                    [alert show];
                    [self callBackDelegateWithPlaybackState:PlayerPlaybackStateFailed];
                
                    break;
                }
                case AVPlayerStatusUnknown:
                default:
                    break;
            }
        }
    } else if (context == (__bridge void *)XHPlayerPreloadObserverContext) {
        if ([keyPath isEqualToString:XHPlayerPlayerLoadedTimeRanges]) {
            NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
            [self updateLoadedTimeRanges:timeRanges];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - custom method

- (void)playBeginning {
    [self hideIndicator];
    [self.player seekToTime:kCMTimeZero];
    [self playCurrentTime];
}

- (void)playCurrentTime {
    if (self.playbackState == PlayerPlaybackStatePlaying) {
        return;
    }
    [self hideIndicator];
    [self play];
    [self callBackDelegateWithPlaybackState:PlayerPlaybackStatePlaying];
}

- (void)showIndicator {
    if ([self.playerView respondsToSelector:@selector(showIndicator)]) {
        [self.playerView showIndicator];
    }
}

- (void)hideIndicator {
    if ([self.playerView respondsToSelector:@selector(hideIndicator)]) {
        [self.playerView hideIndicator];
    }
}

- (void)orientationChanged:(UIDeviceOrientation)orientation{
    UIDeviceOrientation ori = [[UIDevice currentDevice] orientation];
    self.orientation = ori;
}

- (void)stop {
    if (self.playbackState == PlayerPlaybackStateStopped){
        return;
    }
    [self pause];
    [self callBackDelegateWithDidChangeReadDuration:kCMTimeZero];
    [self callBackDelegateWithDidChangeBufferDuration:kCMTimeZero];
    [self callBackDelegateWithPlaybackState:PlayerPlaybackStateStopped];
}

- (void)play {
    if (![self isPlaying]) {
        [self.player play];
    }
}

- (void)pause {
    if ([self isPlaying]) {
        [self.player pause];
        _userPause = YES;
    }
}
- (BOOL)isPlaying {
    return self.player.rate != 0.f;
}
- (void)close{
    
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    
    
    [self.player pause];
    
    _playerView.player = nil;
    [self removeObserverWithPlayer:_player];
    _player = nil;
    
    [self removeNotification];
    
    [self setPlayerItem:nil];
    
    [self setPlayerView:nil];
    
    [self removeFromSuperview];
    
    
}
- (void)dealloc{
    
    NSLog(@"playercontainer dealloc");
    
}
@end