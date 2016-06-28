

//
//  XHVideoPlayController.m
//  XHPlayer
//
//  Created by TianGeng on 16/6/22.
//  Copyright © 2016年 bykernel. All rights reserved.
//

#import "XHVideoPlayController.h"
#import "XHPlayer.h"
#import "XHVideo.h"

@interface XHVideoPlayController ()
@property (nonatomic, strong) XHPlayer *player;
@end

@implementation XHVideoPlayController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    
}
- (XHPlayer *)player{
    if (!_player) {
        _player = [[XHPlayer alloc] init];
        [self.view addSubview:_player];
        self.player.firstSuperView = self.view;
    }
    return _player;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)setVideo:(XHVideo *)video{
    _video = video;
    self.player.frame = CGRectMake(0, 100, 375, 200);
    self.player.mediaPath = video.mp4_url;
    self.player.title = video.title;
    
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.player close];
}


@end
