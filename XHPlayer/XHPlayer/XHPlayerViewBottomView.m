

#define XHVideoName(file) [@"PlayerTool.bundle" stringByAppendingPathComponent:file]
#import "XHPlayerViewBottomView.h"
#import "XHPlayerProgressView.h"
#import "Masonry.h"
#define buttonWH 44 
@interface XHPlayerViewBottomView ()

@property (nonatomic, assign) CGFloat totalTime;

@end


@implementation XHPlayerViewBottomView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:XHVideoName(@"player_touming2@x")]];
        
        UILabel *currentTimeLabel = [[UILabel alloc] init];
        self.currentTimeLabel = currentTimeLabel;
        currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        currentTimeLabel.font = [UIFont systemFontOfSize:14];
        currentTimeLabel.textColor = [UIColor whiteColor];
        currentTimeLabel.text = @"00:00";
        [self addSubview:currentTimeLabel];
        
        UILabel *totalTimeLabel = [[UILabel alloc] init];
        totalTimeLabel.text = @"99:99";
        totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        totalTimeLabel.font = [UIFont systemFontOfSize:14];
        totalTimeLabel.textColor = [UIColor whiteColor];
        self.totalTimeLabel = totalTimeLabel;
        [self addSubview:totalTimeLabel];
        
        UIButton *controlButton = [[UIButton alloc ] init];
        [controlButton setImage:[UIImage imageNamed:XHVideoName(@"player_bofang")] forState:UIControlStateNormal];
        controlButton.selected = YES;
        [controlButton setImage:[UIImage imageNamed:XHVideoName(@"player_pause")] forState:UIControlStateSelected];
        [controlButton addTarget:self action:@selector(controlButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        self.controlButton = controlButton;
        [self addSubview:controlButton];
        
        XHPlayerProgressView *progressView = [XHPlayerProgressView initilzerProgressViewWithFrame:CGRectMake(0, 10, 375, 20)];
        self.progressView = progressView;
        //进度条的拖拽事件
        [progressView addTarget:self action:@selector(sliderChangeValue:)  forControlEvents:UIControlEventValueChanged];
        //进度条的点击事件
        [progressView addTarget:self action:@selector(positionSliderUp:) forControlEvents:UIControlEventTouchUpInside];
         [progressView addTarget:self action:@selector(positionSliderUp:) forControlEvents:UIControlEventTouchUpOutside];
        [progressView addTarget:self action:@selector(positionSliderDown:) forControlEvents:UIControlEventTouchDown];
        
        [self addSubview:progressView];
        
        
        UIButton *fullScreenButton = [[UIButton alloc ] init];
        [fullScreenButton setImage:[UIImage imageNamed:XHVideoName(@"player_fullscreen")] forState:UIControlStateNormal];
        [fullScreenButton setImage:[UIImage imageNamed:XHVideoName(@"player_embeddedscreen")] forState:UIControlStateSelected];
        [fullScreenButton addTarget:self action:@selector(fullScreenButtonClcik:) forControlEvents:UIControlEventTouchUpInside];
        self.fullScreenButton = fullScreenButton;
        [self addSubview:fullScreenButton];
        
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    [self.controlButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(buttonWH, buttonWH));
    }];
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.controlButton.mas_right);
        make.top.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(50, buttonWH));
    }];


    
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(buttonWH, buttonWH));
        make.top.right.equalTo(self);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.right.equalTo(self.fullScreenButton.mas_left).offset(-8);
        make.size.mas_equalTo(CGSizeMake(50, buttonWH));
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).offset(8);
        make.right.equalTo(self.totalTimeLabel.mas_left).offset(-8);
        make.centerY.equalTo(self);
        make.height.equalTo(@(18));
    }];
}

// 根据时间 更新进度条和当前播放时间
- (void)updatePlayingTime:(CGFloat)readDuration{
    self.currentTimeLabel.text = [self convertTime:readDuration * self.totalTime];
    self.progressView.value = readDuration;
}
// 更新总时间
- (void)updateTotalTime:(CGFloat)taotalDuration{
    self.totalTime = taotalDuration;
    self.totalTimeLabel.text = [self convertTime:taotalDuration];
}
// 根据时间 转换成字符串
- (NSString *)convertTime:(CGFloat)second{

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
- (void)updateBufferringTime:(CMTime)bufferDuration{
    [self.progressView setBufferProgress:CMTimeGetSeconds(bufferDuration) * 1.0 / self.totalTime];
}

- (void)controlButtonClick:(UIButton *)controlButton{
    if ([self.delegate respondsToSelector:@selector(playerViewBottomView:didClcikControlButton:)]) {
        [self.delegate playerViewBottomView:self didClcikControlButton:controlButton];
    }
}
- (void)fullScreenButtonClcik:(UIButton *)fullScreenButton{
    if ([self.delegate respondsToSelector:@selector(playerViewBottomView:didClcikFullScreenButton:)]) {
        [self.delegate playerViewBottomView:self didClcikFullScreenButton:fullScreenButton];
    }
}
- (void)sliderChangeValue:(XHPlayerProgressView *)progressView{
    if ([self.delegate respondsToSelector:@selector(playerViewBottomView:didUpdateProgressView:)]) {
        [self.delegate playerViewBottomView:self didUpdateProgressView:progressView];
    }
}
- (void)positionSliderUp:(XHPlayerProgressView *)progressView{
    if ([self.delegate respondsToSelector:@selector(playerViewBottomView:sliderPositionSliderUp:)]) {
        [self.delegate playerViewBottomView:self sliderPositionSliderUp:progressView];
    }
}
- (void)positionSliderDown:(XHPlayerProgressView *)progressView{
    if ([self.delegate respondsToSelector:@selector(playerViewBottomView:sliderPositionSliderDown:)]) {
        [self.delegate playerViewBottomView:self sliderPositionSliderDown:progressView];
    }
}
@end
