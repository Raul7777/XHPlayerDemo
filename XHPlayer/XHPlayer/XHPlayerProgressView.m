
#import "XHPlayerProgressView.h"
#define XHVideoName(file) [@"PlayerTool.bundle" stringByAppendingPathComponent:file]

@interface XHPlayerProgressView ()
@property (nonatomic, strong) CAShapeLayer *bufferProgressLayer;

@property (nonatomic, strong) CAShapeLayer *progressLayer;
@end


@implementation XHPlayerProgressView
+ (instancetype)initilzerProgressView {
    return [self initilzerProgressViewWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen] bounds]), 18)];
}

+ (instancetype)initilzerProgressViewWithFrame:(CGRect)frame {
    XHPlayerProgressView *progressView = [[XHPlayerProgressView alloc] initWithFrame:frame];
    progressView.continuous = YES;
    [progressView setMinimumValue:0.0];
    [progressView setMaximumValue:1.0];
    
    progressView.value = 0.0;

    [progressView setThumbImage:[UIImage imageNamed:XHVideoName(@"player-kit-slider_indicator")] forState:UIControlStateNormal];
    [progressView setMinimumTrackImage:[UIImage imageNamed:XHVideoName(@"player-kit-slider_track_fill")] forState:UIControlStateNormal];
   
    [progressView setMaximumTrackImage: [UIImage imageNamed:XHVideoName(@"player-kit-slider_track_empty")] forState:UIControlStateNormal];
    return progressView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    self.bufferProgress = 0;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.bufferTintColor = [UIColor orangeColor];
    self.progressWidth = 3.0;
    
    CGRect progressBounds = [self trackRectForBounds:self.bounds];
    progressBounds.origin.y -= 1;
    
    
    self.bufferProgressTintColor = [UIColor greenColor];
    self.progressWidth = 3.0;
    self.bufferProgressLayer = [CAShapeLayer layer];
    self.bufferProgressLayer.frame = progressBounds;
    self.bufferProgressLayer.fillColor = nil;
    self.bufferProgressLayer.lineWidth = 2;
    self.bufferProgressLayer.strokeColor = self.bufferProgressTintColor.CGColor;
    self.bufferProgressLayer.strokeStart = 0.0;
    self.bufferProgressLayer.strokeEnd = 0.0;
    [self.layer addSublayer:self.bufferProgressLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bufferProgressLayerFrame = self.bufferProgressLayer.frame;
    bufferProgressLayerFrame.size.width = CGRectGetWidth(self.bounds);
    self.bufferProgressLayer.frame = bufferProgressLayerFrame;
    
    CGRect progressBounds = [self trackRectForBounds:self.bounds];
    
    CGFloat halfHeight = CGRectGetHeight(progressBounds) / 2.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, halfHeight)];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(progressBounds), halfHeight)];
    self.bufferProgressLayer.path = bezierPath.CGPath;
    
//    UIBezierPath *bezierPath2 = [UIBezierPath bezierPath];
//    [bezierPath2 moveToPoint:CGPointMake(0, halfHeight)];
//    [bezierPath2 addLineToPoint:CGPointMake(CGRectGetWidth(progressBounds), halfHeight)];
//    self.progressLayer.path = bezierPath2.CGPath;
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect trackRect = CGRectMake(0, (CGRectGetHeight(bounds) - self.progressWidth) / 2.0, CGRectGetWidth(bounds), self.progressWidth);
    return trackRect;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    CGRect thumbRect = CGRectMake(value * (CGRectGetWidth(self.bounds) - 18), 0.5, 18, 18);
    return thumbRect;
}

#pragma mark - Propertys

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if (_progress == progress) {
        return;
    }
    if (progress > 1.0) {
        progress = 1.0;
    } else if (progress < 0.0 || isnan(progress)) {
        progress = 0.0;
    }
    _progress = progress;
    [self updateProgress];
}

- (void)setBufferProgress:(CGFloat)bufferProgress {
    [self setBufferProgress:bufferProgress animated:NO];
}

- (void)setBufferProgress:(CGFloat)bufferProgress animated:(BOOL)animated {
    if (_bufferProgress == bufferProgress) {
        return;
    }

    if (bufferProgress == INFINITY) { // 当刚初始化播放器的时候 bufferProgress可能为inf
        return;
    }
    if (bufferProgress > 1.0 ) {
        bufferProgress = 1.0;
    } else if (bufferProgress < 0.0 || isnan(bufferProgress)) {
        bufferProgress = 0.0;
    }
    _bufferProgress = bufferProgress;
    [self updateBufferProgress];
}

- (void)setBufferProgressTintColor:(UIColor *)bufferProgressTintColor {
    _bufferProgressTintColor = bufferProgressTintColor;
    self.bufferProgressLayer.strokeColor = bufferProgressTintColor.CGColor;
    [self.bufferProgressLayer setNeedsDisplay];
}

- (void)updateProgress {
    if (self.state == UIControlStateNormal) {
        self.value = self.progress;
    }
//    self.progressLayer.strokeEnd = self.progress;
}

- (void)updateBufferProgress {
    self.bufferProgressLayer.strokeEnd = self.bufferProgress;
}

@end
