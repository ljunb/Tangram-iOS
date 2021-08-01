//
//  XTangramBaseView.m
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import "ITangramRootView.h"
#import <TMUtils/TMUtils.h>
#import "TangramDefaultItemModelFactory.h"
#import "TangramDefaultDataSourceHelper.h"
#import "TangramLayoutProtocol.h"
#import "TangramElementHeightProtocol.h"
#import "TangramContext.h"
#import "TangramEvent.h"

#import "ITangramEngine.h"
#import "ITDefines.h"

@interface ITangramRootView ()

@property (nonatomic, strong) NSOperationQueue *asyncQueue;

@end

@implementation ITangramRootView

- (instancetype)init {
    if (self = [super init]) {
        // use engine tangrambus
        [[ITangramEngine sharedEngine].tangramBus registerAction:NSStringFromSelector(@selector(handleVirtualViewAction:))
                                                      ofExecuter:self
                                                    onEventTopic:kXTangramVVAction
                                            fromPosterIdentifier:kXTangramVVPosterIdentifier];
    }
    return self;
}


#pragma mark - public
- (void)render {
    // start first render
    if (self.loadDelegate && [self.loadDelegate respondsToSelector:@selector(getLayoutLoadKey)]) {
        NSString *loadKey = [self.loadDelegate getLayoutLoadKey];

        if (!loadKey || loadKey.length == 0) {
            return;
        }
        
        // data from cache
        if ([self.loadDelegate respondsToSelector:@selector(getDataFromCache:completion:)]) {
            NSBlockOperation *cacheBlock = [[NSBlockOperation alloc] init];
            
            __weak NSBlockOperation *weakCacheBlock = cacheBlock;
            __weak typeof(self) weakSelf = self;
            [cacheBlock addExecutionBlock:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [weakSelf.loadDelegate getDataFromCache:loadKey completion:^(NSArray * _Nonnull response, BOOL isSuccess) {
                    // return if is cancelled
                    if (weakCacheBlock.isCancelled) {
                        return;
                    }
                    
                    if (strongSelf.hostInstance && [strongSelf.hostInstance respondsToSelector:@selector(tangramView:didLoadFirstRenderData:)]) {
                        [strongSelf.hostInstance tangramView:strongSelf didLoadFirstRenderData:response];
                    }
                }];
            }];
            
            [self.asyncQueue addOperation:cacheBlock];
        }
        
        // data from network
        if ([self.loadDelegate respondsToSelector:@selector(getDataFromNetwork:completion:)]) {
            NSBlockOperation *netBlock = [[NSBlockOperation alloc] init];
            
            __weak typeof(self) weakSelf = self;
            [netBlock addExecutionBlock:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [weakSelf.loadDelegate getDataFromNetwork:loadKey completion:^(NSArray * _Nonnull response, BOOL isSuccess) {
                    // cancel cache operation
                    [strongSelf.asyncQueue cancelAllOperations];
                    
                    if (strongSelf.hostInstance && [strongSelf.hostInstance respondsToSelector:@selector(tangramView:didLoadFirstRenderData:)]) {
                        [strongSelf.hostInstance tangramView:strongSelf didLoadFirstRenderData:response];
                    }
                }];
            }];
            
            [self.asyncQueue addOperation:netBlock];
        }
    }
}


#pragma mark - protected
- (void)startAsyncLoad:(NSString *)loadKey inTargetLayout:(UIView<TangramLayoutProtocol> *)layout itemModel:(TangramDefaultItemModel *)itemModel {
    
    if (self.loadDelegate && [self.loadDelegate respondsToSelector:@selector(asyncLoadJSONDataWithKey:originData:completion:)]) {
        
        __weak typeof(self) weakSelf = self;
        [self.loadDelegate asyncLoadJSONDataWithKey:loadKey originData:itemModel.privateOriginalDict completion:^(NSDictionary * _Nonnull resDict) {
        
            // 空数据
            if (!resDict || resDict.count == 0) {
                return;
            }
            
            // update data
            for (NSString *dictKey in resDict.allKeys) {
                [itemModel setBizValue:[resDict tm_safeObjectForKey:dictKey] forKey:dictKey];
            }
            
            __weak typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                // update height
                Class clazz = NSClassFromString(itemModel.linkElementName);
                if ([clazz conformsToProtocol:@protocol(TangramElementHeightProtocol)]) {
                    Class<TangramElementHeightProtocol> elementClass = NSClassFromString(itemModel.linkElementName);
                    
                    if ([clazz instanceMethodForSelector:@selector(heightByModel:)]) {
                        itemModel.heightFromElement = [elementClass heightByModel:itemModel];
                    }
                }
                // reload target layout
                [strongSelf reloadLayout:layout];
            });
        }];
    }
}


#pragma mark - private
- (void)handleVirtualViewAction:(TangramContext *)context {
    // 非当前绑定的TangramView，直接返回
    if (context.tangram != self) {
        return;
    }
    
    NSString *action = [context.event.params tm_stringForKey:@"action"];
    NSDictionary *originData = [context.event.params tm_safeObjectForKey:@"originData"];
    NSString *reportKey = [context.event.params tm_stringForKey:@"reportKey"];
    
    // invoke
    if (self.loadDelegate && [self.loadDelegate respondsToSelector:@selector(virtualViewDidClickWithAction:reportKey:originData:)]) {
        [self.loadDelegate virtualViewDidClickWithAction:action reportKey:reportKey originData:originData];
    } else if (false) {
        // todo another delegate method
    }
}


#pragma mark - getter
- (NSOperationQueue *)asyncQueue {
    if (!_asyncQueue) {
        _asyncQueue = [[NSOperationQueue alloc] init];
    }
    return _asyncQueue;
}

@end
