//
//  JPDownLoader.m
//  JPDownLoader
//
//  Created by JUMPING on 2017/5/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//


#import "JPDownLoader.h"
#import "JPFileTool.h"

// 把一些常用路径, 抽取成一个宏
#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()




@interface JPDownLoader () <NSURLSessionDataDelegate>
{
    // 记录文件临时下载大小
    long long _tmpSize;
    // 记录文件总大小
    long long _totalSize;
}
/** 下载会话 */
@property (nonatomic, strong) NSURLSession *session;
/** 下载完成路径 */
@property (nonatomic, copy) NSString *downLoadedPath;
/** 下载临时路径 */
@property (nonatomic, copy) NSString *downLoadingPath;
/** 文件输出流 */
@property (nonatomic, strong) NSOutputStream *outputStream;
/** 当前下载任务 */
@property (nonatomic, weak) NSURLSessionDataTask *dataTask;

@end

@implementation JPDownLoader

#pragma mark - 提供给外界的接口

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock {
    
    // 1. 给所有的block赋值
    self.downLoadInfo = downLoadInfo;
    self.progressChange = progressBlock;
    self.successBlock = successBlock;
    self.faildBlock = failedBlock;
    
    // 2. 开始下载
    [self downLoader:url];
    
    
}


/**
 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
 @param url 资源路径
 */
- (void)downLoader:(NSURL *)url {
    
    // 内部实现
    // 1. 真正的从头开始下载
    // 2. 如果任务存在了, 继续下载
    
    // 0. 当前任务, 肯定存在
    if ([url isEqual:self.dataTask.originalRequest.URL]) {
        
        // 下载失败
        // 判断当前的状态, 如果是暂停状态
        if (self.state == JPDownLoadStatePause) {
            // 继续
            [self resumeCurrentTask];
            return;
        }
        
    }

    // 两种: 1. 任务不存在, 2. 任务存在, 但是, 任务的Url地址 不同
    
    [self cacelCurrentTask];
    // 1. 获取文件名称, 指明路径, 开启一个新任务
    NSString *fileName = url.lastPathComponent;
    self.downLoadedPath = [kCachePath stringByAppendingPathComponent:fileName];
    self.downLoadingPath = [kTmpPath stringByAppendingPathComponent:fileName];

    // 1. 判断, url地址, 对应的资源, 是下载完毕,(下载完成的目录里面,存在这个文件)
    // 1.1 告诉外界, 下载完毕, 并且传递相关信息(本地的路径, 文件的大小)
    //     return
    if ([JPFileTool fileExists:self.downLoadedPath]) {
        // UNDO: 告诉外界, 已经下载完成;
//        NSLog(@"已经下载完成");
        self.state = JPDownLoadStatePauseSuccess;
        return;
    }

    // 2. 检测, 临时文件是否存在
    // 2.2 不存在: 从0字节开始请求资源
    //     return
    if (![JPFileTool fileExists:self.downLoadingPath]) {
        // 从0字节开始请求资源
        [self downLoadWithURL:url offset:0];
        return;
    }
  
    _tmpSize = [JPFileTool fileSize:self.downLoadingPath];
    [self downLoadWithURL:url offset:_tmpSize];
}

/**
 暂停任务
 注意:
 - 如果调用了几次继续
 - 调用几次暂停, 才可以暂停
 - 解决方案: 引入状态
 */
- (void)pauseCurrentTask {
    if (self.state == JPDownLoadStateDownLoading) {
        self.state = JPDownLoadStatePause;
        [self.dataTask suspend];
    }
}

/**
 继续任务
 - 如果调用了几次暂停, 就要调用几次继续, 才可以继续
 - 解决方案: 引入状态
 */
- (void)resumeCurrentTask {
    if (self.dataTask && self.state == JPDownLoadStatePause) {
        [self.dataTask resume];
        self.state = JPDownLoadStateDownLoading;
    }

}

/**
 取消当前任务
 */
- (void)cacelCurrentTask {
    self.state = JPDownLoadStatePause;
    [self.session invalidateAndCancel];
    self.session = nil;
}

/**
 取消任务, 并清理资源
 */
- (void)cacelAndClean {
    [self cacelCurrentTask];
    [JPFileTool removeFile:self.downLoadingPath];
    // 下载完成的文件 -> 手动删除某个声音 -> 统一清理缓存
}




#pragma mark - 协议方法

/**
 第一次接受到相应的时候调用(响应头, 并没有具体的资源内容)
 通过这个方法, 里面, 系统提供的回调代码块, 可以控制, 是继续请求, 还是取消本次请求

 @param session 会话
 @param dataTask 任务
 @param response 响应头信息
 @param completionHandler 系统回调代码块, 通过它可以控制是否继续接收数据
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    
    
    // 取资源总大小
    // 1. 从  Content-Length 取出来
    // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
    _totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if (contentRangeStr.length != 0) {
        _totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    // 传递给外界 : 总大小 & 本地存储的文件路径
    if (self.downLoadInfo != nil) {
        self.downLoadInfo(_totalSize);
    }
    
    
    
    // 比对本地大小, 和 总大小
    if (_tmpSize == _totalSize) {
        // 1. 移动到下载完成文件夹
//        NSLog(@"移动文件到下载完成");
        [JPFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        // 2. 取消本次请求
        completionHandler(NSURLSessionResponseCancel);
        
        // 3. 修改状态
        self.state = JPDownLoadStatePauseSuccess;
        
        return;
    }
    
    if (_tmpSize > _totalSize) {
        // 1. 删除临时缓存
//        NSLog(@"删除临时缓存");
        [JPFileTool removeFile:self.downLoadingPath];
        // 2. 取消请求
        completionHandler(NSURLSessionResponseCancel);
        // 3. 从0 开始下载
//        NSLog(@"重新开始下载");
        [self downLoader:response.URL];
        return;
        
    }

    self.state = JPDownLoadStateDownLoading;
    // 继续接受数据
    // 确定开始下载数据
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingPath append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
    
}
    

/**
 当用户确定, 继续接受数据的时候调用

 @param session 会话
 @param dataTask 任务
 @param data 接受到的一段数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // 这就是当前已经下载的大小
    _tmpSize += data.length;
    
    self.progress =  1.0 * _tmpSize / _totalSize;

    // 往输出流中写入数据
    [self.outputStream write:data.bytes maxLength:data.length];
//    NSLog(@"在接收后续数据");
}


/**
 请求完成时候调用
 请求完成的时候调用( != 请求成功/失败)
 @param session 会话
 @param task 任务
 @param error 错误
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
//    NSLog(@"请求完成");
    if (error == nil) {
        // 不一定是成功
        // 数据是肯定可以请求完毕
        // 判断, 本地缓存 == 文件总大小 {filename: filesize: md5:xxx}
        // 如果等于 => 验证, 是否文件完整(file md5 )
        
        [JPFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        self.state = JPDownLoadStatePauseSuccess;
        
    }else {
        
        
//        NSLog(@"有问题--%zd--%@", error.code, error.localizedDescription);
        // 取消,  断网
        // 999 != 999
        if (-999 == error.code) {
            self.state = JPDownLoadStatePause;
        }else {
            self.state = JPDownLoadStatePauseFailed;
        }
        
    }
    [self.outputStream close];
    
}


#pragma mark - 私有方法
/**
 根据开始字节, 请求资源
 
 @param url url
 @param offset 开始字节
 */
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    // 通过控制range, 控制请求资源字节区间
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    // session 分配的task, 默认情况, 挂起状态
    self.dataTask = [self.session dataTaskWithRequest:request];
    [self resumeCurrentTask];
    
}


#pragma mark - 懒加载
/**
 懒加载会话
 @return 会话
 */
- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
    
    
#pragma mark - 事件/数据传递
- (void)setState:(JPDownLoadState)state {
    // 数据过滤
    if(_state == state) {
        return;
    }
    _state = state;
    
    // 代理, block, 通知
    if (self.stateChange) {
        self.stateChange(_state);
    }
    
    if (_state == JPDownLoadStatePauseSuccess && self.successBlock) {
        self.successBlock(self.downLoadedPath);
    }
    
    if (_state == JPDownLoadStatePauseFailed && self.faildBlock) {
        self.faildBlock();
    }
    
}


- (void)setProgress:(float)progress {
    _progress = progress;
    if (self.progressChange) {
        self.progressChange(_progress);
    }
}
    
    
@end
