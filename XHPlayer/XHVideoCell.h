//
//  XHVideoCell.h
//  XHPlayer
//
//  Created by TianGeng on 16/6/22.
//  Copyright © 2016年 bykernel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XHVideo;
@interface XHVideoCell : UITableViewCell
@property (nonatomic, strong) XHVideo *video;

@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;
+ (instancetype)videoCellWithTableView:(UITableView *)tableView;
@end
