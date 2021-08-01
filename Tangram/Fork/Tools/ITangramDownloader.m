//
//  XTangramDownloader.m
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import "ITangramDownloader.h"
#import <SSZipArchive/SSZipArchive.h>

static NSString *const kXPComponentsFolderName = @"IComponents";
static NSString *const kXPComponentsZipFileName = @"IComponents.zip";
static NSString *const kXPComponentsMD5FileName = @"IComponentMD5";


@implementation ITangramDownloader

+ (void)downloadComponentsIfNeedWithUrl:(NSString *)url remoteMD5:(NSString *)remoteMD5 {
    if (!url || url.length == 0) { return; }
    
    NSError *error = nil;
    // bundle或文件中的MD5文件
    NSString *localMD5Path = [self getComponentMD5FilePath];
    NSString *localMD5 = [NSString stringWithContentsOfFile:localMD5Path
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    // 读取本地MD5失败
    if (error) {
        NSLog(@"读取本地MD5失败");
        return;
    }
    
    // 与本地MD5不一致，下载组件
    if (![localMD5 isEqualToString:remoteMD5]) {
        NSString *filePath = [self getDownloadPath];
        
        if(![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
            const BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:nil];
            if (isSuccess) {
                NSLog(@"新建Tangram下载目录成功 %@", filePath);
            } else {
                NSLog(@"新建Tangram下载目录失败");
            }
        }
        
        NSLog(@"开始下载Tangram组件……");
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url]
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"下载Tangram组件成功");
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // zip存放目录
                NSString *remoteFilePath = [filePath stringByAppendingPathComponent:kXPComponentsZipFileName];
                
                BOOL isSuccess = [data writeToFile:remoteFilePath options:NSDataWritingAtomic error:nil];
                // 写入失败
                if (!isSuccess) {
                    NSLog(@"写入组件zip失败");
                    return;
                }
                
                NSString *unzippedPath = [filePath stringByAppendingPathComponent:@"unzipped"];
                if (![NSFileManager.defaultManager fileExistsAtPath:unzippedPath]) {
                    isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:unzippedPath
                                                          withIntermediateDirectories:YES
                                                                           attributes:nil
                                                                                error:nil];
                    
                    if (isSuccess) {
                        NSLog(@"新建Tangram解压目录成功 %@", unzippedPath);
                    } else {
                        NSLog(@"新建Tangram解压目录失败");
                    }
                }
                
                isSuccess = [SSZipArchive unzipFileAtPath:remoteFilePath toDestination:unzippedPath];
                // 解压失败，直接返回
                if (!isSuccess) {
                    return;
                }
                
                // 重命名所有的组件
                [self cleanMD5InComponentNameAtPath:unzippedPath];
                
                // 目标目录：Tangram/XPComponents
                NSString *componentsPath = [[self getTangramPath] stringByAppendingPathComponent:kXPComponentsFolderName];
                isSuccess = [self copyFileFromPath:unzippedPath toPath:componentsPath];
                
                if (isSuccess) {
                    // 移除下载目录
                    [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
                    
                    // 保存新的MD5，只针对当前文件目录
                    NSString *targtMD5FilePath = [[self getTangramPath] stringByAppendingPathComponent:kXPComponentsMD5FileName];
                    NSData *newMD5Data = [remoteMD5 dataUsingEncoding:NSUTF8StringEncoding];
                    isSuccess = [newMD5Data writeToFile:targtMD5FilePath options:NSDataWritingAtomic error:nil];

                    if (!isSuccess) {
                        [self removeTangramPath];
                    }
                } else {
                    [self removeTangramPath];
                    // 移除下载目录
                    [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
                }
            });
        }];
        [task resume];
    } else {
        NSLog(@"本地和远程MD5一致，不更新组件");
    }
}


#pragma mark - 组件目录 & 下载相关
+ (NSString *)getDownloadPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"TangramResourceDownload"];
}

+ (NSString *)getTangramPath {
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    return [appSupportDir stringByAppendingPathComponent:@"Tangram"];
}

+ (NSString *)getBinaryPath {
    return [[NSBundle mainBundle] resourcePath];
}

/**
 binary version: XiaoPengQiChe.app/xxx.out
 file version: Tangram/XPComponents/xxx.out
 */
+ (NSString *)getTangramComponentsPath {
    NSString *result = [self getBinaryPath];
    if ([self isExistsTangramComponents]) {
        result = [[self getTangramPath] stringByAppendingPathComponent:kXPComponentsFolderName];
    }
    NSLog(@"getTangramComponentsPath %@", result);
    return result;
}

/**
 binary version: XX.app/IComponentMD5
 file version: Tangram/IComponentMD5
 */
+ (NSString *)getComponentMD5FilePath {
    NSString *result = [[self getBinaryPath] stringByAppendingPathComponent:kXPComponentsMD5FileName];
    if ([self isExistsTangramComponents]) {
        result = [[self getTangramPath] stringByAppendingPathComponent:kXPComponentsMD5FileName];
    }
    NSLog(@"getComponentMD5FilePath %@", result);
    return result;
}

+ (BOOL)isExistsTangramComponents {
    BOOL isDir = YES;
    // 存在Tangram目录
    if ([NSFileManager.defaultManager fileExistsAtPath:[self getTangramPath] isDirectory:&isDir]) {
        NSString *md5FilePath = [[self getTangramPath] stringByAppendingPathComponent:kXPComponentsMD5FileName];
        // 存在MD5校验文件
        if ([NSFileManager.defaultManager fileExistsAtPath:md5FilePath]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)copyFileFromPath:(NSString *)sourcePath toPath:(NSString *)toPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL result = YES;
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
    if (!files) {
        return NO;
    }
    
    if (![fileManager fileExistsAtPath:toPath]) {
        //不存在目标目录，则创建
        [fileManager createDirectoryAtPath:toPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return NO;
        }
    }
    
    for (NSString *fileName in files) {
        NSString *sourceFullFilePath = [sourcePath stringByAppendingPathComponent:fileName];
        BOOL isDir = NO;
        // nested folder
        if ([fileManager fileExistsAtPath:sourceFullFilePath isDirectory:&isDir] && isDir) {
            NSString *nestedFolderPath = [toPath stringByAppendingPathComponent:fileName];
            result = [self copyFileFromPath:sourceFullFilePath toPath:nestedFolderPath];
            if (!result) {
                return NO;
            }
        } else {
            NSString *toFullFilePath = [toPath stringByAppendingPathComponent:fileName];
            // remove old item
            if ([fileManager fileExistsAtPath:toFullFilePath]) {
                result = [fileManager removeItemAtPath:toFullFilePath error:&error];
                if (!result) {
                    return NO;
                }
            }
            
            result = [fileManager copyItemAtPath:sourceFullFilePath toPath:toFullFilePath error:&error];
            if (!result) {
                return NO;
            }
        }
    }
    return YES;
}

// 直接删除Tangram目录，走保底版本，下次再检查更新
+ (BOOL)removeTangramPath {
    BOOL isDir = YES;
    if ([NSFileManager.defaultManager fileExistsAtPath:[self getTangramPath] isDirectory:&isDir]) {
        return [NSFileManager.defaultManager removeItemAtPath:[self getTangramPath] error:nil];
    }
    return YES;
}

+ (void)cleanMD5InComponentNameAtPath:(NSString *)path {
    NSArray* array = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil];
    for (int i = 0; i < [array count]; i++) {
        NSString *originName = [array objectAtIndex:i];
        NSString *pureName = [[[[originName componentsSeparatedByString:@".out"] firstObject] componentsSeparatedByString:@"-"] firstObject] ?: @"";
        if (!pureName || pureName.length == 0) {
            continue;
        }
        
        NSString *fullPath = [path stringByAppendingPathComponent:originName];
        NSString *renamePath = [path stringByAppendingPathComponent:[pureName stringByAppendingString:@".out"]];
        
        BOOL isSuccess = [NSFileManager.defaultManager moveItemAtPath:fullPath toPath:renamePath error:nil];
        if (isSuccess) {
            NSLog(@"清除组件名称MD5成功: %@", renamePath);
        } else {
            NSLog(@"清除组件名称MD5失败: %@", renamePath);
        }
    }
}

@end
