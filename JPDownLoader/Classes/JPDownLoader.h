//
//  JPDownLoader.h
//  JPDownLoader
//
//  Created by JUMPING on 2017/5/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, JPDownLoadState) {
    JPDownLoadStatePause,
    JPDownLoadStateDownLoading,
    JPDownLoadStatePauseSuccess,
    JPDownLoadStatePauseFailed
};


typedef void(^DownLoadInfoType)(long long totalSize);
typedef void(^ProgressBlockType)(float progress);
typedef void(^SuccessBlockType)(NSString *filePath);
typedef void(^FailedBlockType)();
typedef void(^StateChangeType)(JPDownLoadState state);


// 一个下载器, 对应一个下载任务
// JPDownLoader -> url
@interface JPDownLoader : NSObject



- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock;
/**
 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
 @param url 资源路径
 */
- (void)downLoader:(NSURL *)url;
- (void)resumeCurrentTask;
/**
 暂停任务
 注意:
 - 如果调用了几次继续
 - 调用几次暂停, 才可以暂停
 - 解决方案: 引入状态
 */
- (void)pauseCurrentTask;

/**
 取消任务
 */
- (void)cacelCurrentTask;

/**
 取消任务, 并清理资源
 */
- (void)cacelAndClean;



/// 数据
/// 事件&数据
@property (nonatomic, assign, readonly) JPDownLoadState state;
@property (nonatomic, assign, readonly) float progress;

@property (nonatomic, copy) DownLoadInfoType downLoadInfo;
@property (nonatomic, copy) StateChangeType stateChange;
@property (nonatomic, copy) ProgressBlockType progressChange;
@property (nonatomic, copy) SuccessBlockType successBlock;
@property (nonatomic, copy) FailedBlockType faildBlock;

// delegate

@end
