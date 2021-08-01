//
//  XTangramBaseView.h
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import "TangramView.h"
#import "ITangramViewLoadProtocol.h"

@class TangramDefaultItemModel;
@class ITangramRootView;

NS_ASSUME_NONNULL_BEGIN

@protocol ITangramViewHostProtocol <NSObject>

/// 完成首屏渲染内容获取
///
/// @param tangramView 页面绑定的tangramView实例
/// @param data 首屏渲染内容数组
- (void)tangramView:(ITangramRootView *)tangramView didLoadFirstRenderData:(NSArray *)data;

@end

@interface ITangramRootView : TangramView

/// 数据加载相关代理
@property (nonatomic, weak) id<ITangramViewLoadProtocol> loadDelegate;
/// TangramView宿主对象
@property (nonatomic, weak) id<ITangramViewHostProtocol> hostInstance;

/// 首屏渲染方法
- (void)render;

@end

NS_ASSUME_NONNULL_END
