
//
#import <MediaPlayer/MediaPlayer.h>
#import "XHPlayerView.h"
#import "XHPlayerViewBottomView.h"
#import "XHForwardView.h"
#import "Masonry.h"

@interface XHPlayerView ()
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign) NSInteger totalTime;

@property (nonatomic, assign) CGPoint startPoint;

@property (nonatomic, assign) BOOL isChangingVolume;


@property (nonatomic, strong) XHForwardView *forwardView;

@property (nonatomic, assign) CGFloat seconds;


@property (nonatomic, strong) NSTimer *clickTimer;
@end

CGFloat const gestureMinimumTranslation = 5.0;

@implementation XHPlayerView
#pragma mark - 实例化视图
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)commit {
    self.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
    self.videoFillMode = AVLayerVideoGravityResizeAspect;
    
    [self setUpTopView];
    [self setupBottomView];
    [self setUpIndicorView];
    [self addGesture];

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commit];
    }
    return self;
}

- (void)awakeFromNib {
    [self commit];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (void)setVideoFillMode:(NSString *)videoFillMode {
    [self playerLayer].videoGravity = videoFillMode;
}

- (NSString *)videoFillMode {
    return [self playerLayer].videoGravity;
}
#pragma mark - 初始化控件

- (void)setUpTopView{

    XHPlayerViewTopView *topView = [[XHPlayerViewTopView alloc] init];
    [topView.backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.topView = topView;
    [self addSubview:topView];

}
- (void)setupBottomView{
    XHPlayerViewBottomView *bottomView = [[XHPlayerViewBottomView alloc] init];
    self.bottomView = bottomView;
    [self addSubview:bottomView];
}
- (void)setUpIndicorView{
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:indicatorView];
    self.indicatorView = indicatorView;
    indicatorView.hidesWhenStopped = YES;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.equalTo(@44);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.height.equalTo(@(44));
    }];
    
    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
}
#pragma mark - 更新ui界面
/**
 *  更新时间
 *
 *  @param readDuration 时间
 */
- (void)updatePlayingTime:(CMTime)readDuration{
    NSInteger currentTime = readDuration.value/readDuration.timescale;
    self.bottomView.currentTimeLabel.text = [self convertTime:currentTime];
    self.bottomView.progressView.value = currentTime  * 1.0/ self.totalTime;
}
/**
 *  更新总时间
 *
 *  @param taotalDuration 总时间
 */
- (void)updateTotalTime:(CMTime)taotalDuration{
    self.totalTime =taotalDuration.value / taotalDuration.timescale;
    self.bottomView.totalTimeLabel.text = [self convertTime:self.totalTime];
}


- (void)setOrientation:(UIDeviceOrientation)orientation{
    _orientation = orientation;
    
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        self.bottomView.fullScreenButton.selected = YES;
    }if (orientation == UIDeviceOrientationPortrait ){
        self.bottomView.fullScreenButton.selected = NO;
    }
}
#pragma mark - 显示菊花的控件
- (void)showIndicator {
    [self.indicatorView startAnimating];
}
- (void)hideIndicator {
    [self.indicatorView stopAnimating];
}

#pragma mark - custom method

- (void)backButtonClick{
    if ([self.delegate respondsToSelector:@selector(playerViewDidClickBackButton)]) {
        [self.delegate playerViewDidClickBackButton];
    }
}

- (NSString *)convertTime:(NSInteger)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}
/**
 *  添加手势
 */
- (void)addGesture{
    // 添加单击手势
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(singleTap)];
    
    [self addGestureRecognizer:singleTap];
    
    // 添加双击手势
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    [singleTap requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    
    // 添加拖拽手势
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [self addGestureRecognizer:recognizer];
    
}
/**
 *  单击手势
 */
- (void)singleTap{
    
    if (self.topView.alpha == 1.0) {
        [UIView animateWithDuration:0.25 animations:^{
        
            // 点击view消失
            self.topView.alpha = 0.0;
            self.bottomView.alpha = 0.0;
        }];
        
        
    } else {
        
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.topView.alpha = 1;
            self.bottomView.alpha = 1;
        }];
    }
    [self resetIdleTimer];
}
/**
 *  双击手势
 *
 *  @param recognizer 手势操作
 */
- (void)doubleTap:(UITapGestureRecognizer *)recognizer{
    
    CGPoint location = [recognizer locationInView:self];
    if (location.y <= CGRectGetMaxY(self.topView.frame)||location.y >= CGRectGetMinY(self.bottomView.frame)) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(playViewDidDoubleTap)]) {
        [self.delegate playViewDidDoubleTap];
    }
}

- (void)handleSwipe:(UIPanGestureRecognizer *)gesture
{
    
    self.widthSeconds = (self.widthSeconds == 0) ? 90 : self.widthSeconds;
    
    
    CGFloat percentLength = self.widthSeconds / self.frame.size.width;
    
    CGFloat panDirectionY = [gesture velocityInView:gesture.view].y;
    CGPoint translation = [gesture translationInView:gesture.view];
    if (gesture.state ==UIGestureRecognizerStateBegan)
    {
        self.direction = PanDirectionNone;
        self.startPoint = [gesture locationInView:gesture.view];
        
    }
    if (gesture.state == UIGestureRecognizerStateChanged )
    {
        self.direction = [self determinePanDirectionIfNeeded:translation];
        
        switch (self.direction) {
            case PanDirectionUp:
            case PanDirectionDown:
            {
                self.isChangingVolume = YES;
//
                if (panDirectionY > 0) {

                
                    MPMusicPlayerController* musicController = [MPMusicPlayerController applicationMusicPlayer];
                    musicController.volume -= 0.01;
                }
                else{
                    MPMusicPlayerController* musicController = [MPMusicPlayerController applicationMusicPlayer];
                    musicController.volume += 0.01;

                }
                
                break;
            }
                
            case PanDirectionRight: // 向右划(快进)
            {
               
             
                self.forwardView.hidden = NO;
                self.forwardView.mode = XHForwardViewModeForward; // 快进模式
                
                CGPoint endPoint = [gesture locationInView:gesture.view];
                int panLength = endPoint.x - self.startPoint.x;
                if (panLength > 0) {
                    // 计算滑动的距离显示 
                    NSInteger timeLength = panLength * percentLength;
                    self.forwardView.timeLabel.text = [self convertTime:timeLength];
                }else{
                    // 否则开始向左划 快退显示
                    self.forwardView.mode = XHForwardViewModeRewind;
                    CGPoint endPoint = [gesture locationInView:gesture.view];
                    int panLength = endPoint.x - self.startPoint.x;
                    int timeLength = panLength * percentLength * -1;
                    self.forwardView.timeLabel.text =  [self convertTime:timeLength];
                }
                
                break;
            }
            case PanDirectionLeft: // 向左划 快退手势
            {
                self.forwardView.hidden = NO;
                self.forwardView.mode = XHForwardViewModeRewind;
                
//                if (self.coverView.alpha) {
//                    self.coverView.alpha = 0;
//                }
                CGPoint endPoint = [gesture locationInView:gesture.view];
                int panLength = endPoint.x - self.startPoint.x;
                if (panLength <  0) {
                    
                    self.forwardView.mode = XHForwardViewModeRewind;
                    int timeLength = panLength * percentLength * -1;
                    
                    self.forwardView.timeLabel.text = [self convertTime:timeLength];
                }else{
                    self.forwardView.mode = XHForwardViewModeForward;
                    
                    CGPoint endPoint = [gesture locationInView:gesture.view];
                    int panLength = endPoint.x - self.startPoint.x;
                    
                    int timeLength = panLength * percentLength;
    
                    self.forwardView.timeLabel.text = [self convertTime:timeLength];
                }
            }
                
            default:
                break;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // now tell the camera to stop
        
        if (!self.isChangingVolume) {
            if (self.forwardView.hidden == NO) {
                self.forwardView.hidden = YES;
            }
            
            CGPoint endPoint = [gesture locationInView:gesture.view];
            CGFloat panLength = endPoint.x - self.startPoint.x;
            
            NSLog(@"%f",panLength);
            self.seconds = panLength *  percentLength ;
            
            
            if ([self.delegate respondsToSelector:@selector(playViewDidSwipeOver:)]) {
                [self.delegate playViewDidSwipeOver:self.seconds];
            }
        }
        self.isChangingVolume = NO;
    }
}
// This method will determine whether the direction of the user's swipe
- (PanDirection)determinePanDirectionIfNeeded:(CGPoint)translation
{
    if (self.direction != PanDirectionNone)
        return self.direction;
    if (fabs(translation.x) > gestureMinimumTranslation)
    {
        BOOL gestureHorizontal = NO;
        if (translation.y ==0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) >5.0);
        if (gestureHorizontal)
        {
            if (translation.x >0.0)
                return PanDirectionRight;
            else
                return PanDirectionLeft;
        }
    }
    else if (fabs(translation.y) > gestureMinimumTranslation)
    {
        BOOL gestureVertical = NO;
        if (translation.x ==0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) >5.0);
        if (gestureVertical)
        {
            if (translation.y >0.0)
                return PanDirectionDown;
            else
                return PanDirectionUp;
        }
    }
    return self.direction;
}
- (XHForwardView *)forwardView{
    if (!_forwardView) {
        _forwardView = [[XHForwardView alloc] init];
        [self addSubview:_forwardView];
        self.forwardView.hidden = NO;
        [_forwardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(100, 40));
        }];
    }
    return _forwardView;
    
}
- (void)resetIdleTimer
{
    if (!_clickTimer) {
        _clickTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(idleTimerExceeded)
                                                     userInfo:nil
                                                      repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.clickTimer forMode:NSRunLoopCommonModes];
    } else {
        if (fabs([self.clickTimer.fireDate timeIntervalSinceNow]) < 5.0)
            [self.clickTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    }
}

- (void)idleTimerExceeded
{
    [self.clickTimer invalidate];
    self.clickTimer = nil;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.topView.alpha = 0.0;
        self.bottomView.alpha = 0.0;
    }];
    
}
@end
