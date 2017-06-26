//
//  JPDownLoaderManager.m
//  JPDownLoader
//
//  Created by JUMPING on 2017/5/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//


#import "JPDownLoaderManager.h"
#import "NSString+SZ.h"
@interface JPDownLoaderManager()<NSCopying, NSMutableCopying>

//@property (nonatomic, strong) JPDownLoader *downLoader;


@property (nonatomic, strong) NSMutableDictionary *downLoadInfo;



@end

@implementation JPDownLoaderManager

static JPDownLoaderManager *_shareInstance;
+ (instancetype)shareInstance {
    if (_shareInstance == nil) {
        _shareInstance = [[self alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _shareInstance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _shareInstance;
}

// key: md5(url)  value: JPDownLoader
- (NSMutableDictionary *)downLoadInfo {
    if (!_downLoadInfo) {
        _downLoadInfo = [NSMutableDictionary dictionary];
    }
    return _downLoadInfo;
}


- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock {
    
    // 1. url
    NSString *urlMD5 = [url.absoluteString md5];
    
    // 2. 根据 urlMD5 , 查找相应的下载器
    JPDownLoader *downLoader = self.downLoadInfo[urlMD5];
    if (downLoader == nil) {
        downLoader = [[JPDownLoader alloc] init];
        self.downLoadInfo[urlMD5] = downLoader;
    }
    
//    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:successBlock failed:failedBlock];
    
    __weak typeof(self) weakSelf = self;
    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:^(NSString *filePath) {
        
        [weakSelf.downLoadInfo removeObjectForKey:urlMD5];
        // 拦截block
        successBlock(filePath);
    } failed:failedBlock];
    
    
    
    // 下载完成之后, 移除下载器
    //
    
}


- (void)pauseWithURL:(NSURL *)url {
    
    NSString *urlMD5 = [url.absoluteString md5];
    JPDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader pauseCurrentTask];
}
- (void)resumeWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5];
    JPDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader resumeCurrentTask];
}
- (void)cancelWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5];
    JPDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader cacelCurrentTask];

}


- (void)pauseAll {
    
    [self.downLoadInfo.allValues performSelector:@selector(pauseCurrentTask) withObject:nil];
    
}
- (void)resumeAll {
     [self.downLoadInfo.allValues performSelector:@selector(resumeCurrentTask) withObject:nil];
}

@end
