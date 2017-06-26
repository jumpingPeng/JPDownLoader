//
//  NSString+SZ.m
//  JPDownLoader
//
//  Created by JUMPING on 2017/5/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//


#import "NSString+SZ.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (SZ)

- (NSString *)md5 {
    
    const char *data = self.UTF8String;

    unsigned char md[CC_MD5_DIGEST_LENGTH];
    
    // 作用: 把c语言的字符串 -> md5 c字符串
    CC_MD5(data, (CC_LONG)strlen(data), md);
    
    
    // 32
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", md[i]];
    }
    
    return result;
  
}


@end
