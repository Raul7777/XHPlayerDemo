//
//  XHVideoCell.m
//  XHPlayer
//
//  Created by TianGeng on 16/6/22.
//  Copyright © 2016年 bykernel. All rights reserved.
//

#import "XHVideoCell.h"
#import "UIImageView+WebCache.h"
#import "XHVideo.h"

@interface XHVideoCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorTitle;
@property (weak, nonatomic) IBOutlet UILabel *playCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@end


@implementation XHVideoCell


+ (instancetype)videoCellWithTableView:(UITableView *)tableView{
    XHVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"videoCell"];
    if (cell == nil) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"XHVideoCell" owner:self options:nil].lastObject;
    }
    return cell;
}


- (void)awakeFromNib {
    [super awakeFromNib];

    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setVideo:(XHVideo *)video{
    _video = video;
    [self.videoImageView sd_setImageWithURL:[NSURL URLWithString:video.cover]];
    
    [self.authorImageView sd_setImageWithURL:[NSURL URLWithString:video.topicImg]];
    
    self.titleLabel.text = video.title;
    self.authorTitle.text = video.topicName;
    self.playCountLabel.text = [NSString stringWithFormat:@"%zd次播放",video.playCount];
}

@end
