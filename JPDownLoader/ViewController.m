//
//  ViewController.m
//  JPDownLoader
//
//  Created by JUMPING on 2017/5/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//


#import "ViewController.h"
//#import "JPDownLoader.h"
#import "JPDownLoaderManager.h"

@interface ViewController ()

//@property (nonatomic, strong) JPDownLoader *downLoader;

@property (nonatomic, weak) NSTimer *timer;

@end

@implementation ViewController

- (NSTimer *)timer {
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        _timer = timer;
    }
    return _timer;
}




- (void)update {
       // NSLog(@"现在的状态----%zd", self.downLoader.state);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    [self timer];
    
}

- (IBAction)download:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://free2.macx.cn:8281/tools/photo/SnapNDragPro418.dmg"];
    
    NSURL *url2 = [NSURL URLWithString:@"http://free2.macx.cn:8281/tools/photo/Sip44.dmg"];
    
    
    [[JPDownLoaderManager shareInstance] downLoader:url2 downLoadInfo:^(long long totalSize) {
        NSLog(@"下载信息--%lld", totalSize);
    } progress:^(float progress) {
        NSLog(@"下载进度--%f", progress);
    } success:^(NSString *filePath) {
        NSLog(@"下载成功--路径:%@", filePath);
    } failed:^{
        NSLog(@"下载失败了");
    }];
    
    [[JPDownLoaderManager shareInstance] downLoader:url downLoadInfo:^(long long totalSize) {
        NSLog(@"下载信息--%lld", totalSize);
    } progress:^(float progress) {
        NSLog(@"下载进度--%f", progress);
    } success:^(NSString *filePath) {
        NSLog(@"下载成功--路径:%@", filePath);
    } failed:^{
        NSLog(@"下载失败了");
    }];
    
    //    [self.downLoader downLoader:url];
    //    [self.downLoader downLoader:url downLoadInfo:^(long long totalSize) {
    //        NSLog(@"下载信息--%lld", totalSize);
    //    } progress:^(float progress) {
    //        NSLog(@"下载进度--%f", progress);
    //    } success:^(NSString *filePath) {
    //        NSLog(@"下载成功--路径:%@", filePath);
    //    } failed:^{
    //        NSLog(@"下载失败了");
    //    }];
    
    //    [self.downLoader setStateChange:^(JPDownLoadState state){
    //        NSLog(@"---%zd", state);
    //    }];
}
- (IBAction)pause:(id)sender {
    //    [self.downLoader pauseCurrentTask];
}
- (IBAction)cancel:(id)sender {
    //    [self.downLoader cacelCurrentTask];
}
- (IBAction)cancelClean:(id)sender {
    //    [self.downLoader cacelAndClean];
}



@end
