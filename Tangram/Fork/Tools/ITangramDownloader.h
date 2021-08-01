//
//  XTangramDownloader.h
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ITangramDownloader : NSObject

/// 本地是否存在Tangram组件的文件目录
+ (BOOL)isExistsTangramComponents;

/**
 获取Tangram组件目录路径，如有下载的组件，则返回文件目录 Application Support/Tangram/XPComponents/，否则返回main bundle目录
 */
+ (NSString *)getTangramComponentsPath;

/**
 根据远程组件URL和MD5，按需下载Tangram组件
 */
+ (void)downloadComponentsIfNeedWithUrl:(NSString *)url remoteMD5:(NSString *)remoteMD5;

@end

NS_ASSUME_NONNULL_END
