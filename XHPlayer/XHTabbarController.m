//
//  XHTabbarController.m
//  XHPlayer
//
//  Created by TianGeng on 16/6/22.
//  Copyright © 2016年 bykernel. All rights reserved.
//

#import "XHTabbarController.h"
#import "XHFunnyViewController.h"
#import "XHMusicViewController.h"
#import "XHNavgationController.h"

@interface XHTabbarController ()

@end

@implementation XHTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    XHFunnyViewController *funny = [[XHFunnyViewController alloc] init];
    funny.title = @"搞笑";
    XHNavgationController *nav = [[XHNavgationController alloc] initWithRootViewController:funny];
    [self addChildViewController:nav];
    
    XHMusicViewController *music = [[XHMusicViewController alloc] init];
    music.title = @"音乐";
    XHNavgationController *nav2 = [[XHNavgationController alloc] initWithRootViewController:music];
    [self addChildViewController:nav2];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
