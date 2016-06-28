

/**
 数据 来源 网易新闻客户端
 */





#import "XHFunnyViewController.h"
#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"
#import "YYModel.h"
#import "XHVideo.h"
#import "XHVideoCell.h"
#import "XHVideoPlayController.h"
#import "XHPlayer.h"

@interface XHFunnyViewController ()
@property (nonatomic, copy) NSString *tid;
@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong) NSMutableArray *videoArray;

@property (nonatomic, strong) XHPlayer *player;

@property (nonatomic, strong) XHVideoCell *selectCell;

@property (nonatomic, strong) NSIndexPath *selectIndexPath;
@end

@implementation XHFunnyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tid = @"T1457069041911";
    self.index = 0;
    
    self.videoArray = [NSMutableArray array];
    // 请求地址
    NSString *urlString = [NSString stringWithFormat:@"http://c.m.163.com/nc/video/Tlist/%@/%zd-10.html",self.tid,self.index];

    [self getWithUrl:urlString params:nil success:^(NSDictionary *responseObject) {
        NSArray *array = responseObject[self.tid];
        for (NSDictionary *dict in array) {
            XHVideo *video = [XHVideo yy_modelWithDictionary:dict];
            [self.videoArray addObject:video];
        }
        [self.tableView reloadData];
        
        NSLog(@"%@",responseObject);
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.rowHeight = 205;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.videoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XHVideoCell *cell = [XHVideoCell videoCellWithTableView:tableView];
    XHVideo *video = self.videoArray[indexPath.row];
    
    cell.video = video;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    
    XHVideoCell *cell = (XHVideoCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (self.selectCell == cell) {
        return;
    }
    
    if (_player) {
        [self.player close];
        self.player = nil;

    }
    
    XHVideo *video = self.videoArray[indexPath.row];
    self.player.mediaPath = video.mp4_url;
    self.player.frame = cell.videoImageView.bounds;
    [cell addSubview:self.player];
    [cell bringSubviewToFront:self.player];
    
    self.player.firstSuperView = cell;
    self.player.title = video.title;
    self.selectCell = cell;
    self.selectIndexPath = indexPath;

}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView == self.tableView) {
        NSArray *indexArray = [self.tableView indexPathsForVisibleRows];
        if (![indexArray containsObject:self.selectIndexPath]) {
           
            if (_player) {
                [_player close];
                _player = nil;
            }
        }
    }
}
- (XHPlayer *)player{
    if (!_player) {
        _player = [[XHPlayer alloc] init];
    }
    return _player;
}
- (void)getWithUrl:(NSString *)url params:(NSDictionary *)params success:(void(^)(id responseObject))success failure:(void (^)(NSError *error))failure{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //发送get请求
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //加载成功,把数据回调回去
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (_player) {
        [_player close];
        _player = nil;
    }
}
@end
