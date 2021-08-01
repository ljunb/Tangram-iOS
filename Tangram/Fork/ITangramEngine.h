//
//  XTangramEngine.h
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import <Foundation/Foundation.h>
#import "ITangramViewLoadProtocol.h"

@class TangramDefaultItemModel;
@class TangramBus;

NS_ASSUME_NONNULL_BEGIN


@interface ITangramEngine : NSObject

/// 所有已加载注册的虚拟组件名称
@property (nonatomic, copy, readonly) NSArray<NSString *> *vvComponents;
/// 所有已注册的内置组件名称
@property (nonatomic, copy, readonly) NSArray<NSString *> *tangramComponents;
/// 事件总线实例
@property (nonatomic, strong) TangramBus *tangramBus;

/// 单例
+ (instancetype)sharedEngine;

/// 添加自定义组件的type和class映射
///
/// 例如：@{ @"OrderLocationView": OrderLocationViewElement.class }
///
/// @param elementClassMap 组件type和class名称映射字典
- (void)addElementClassMap:(NSDictionary *)elementClassMap;

/// 基于给定的源数据，返回布局数组
///
/// @param dictArray 布局原始数据
/// @return 布局数组
+ (NSArray<UIView<TangramLayoutProtocol> *> *)layoutsWithArray:(NSArray<NSDictionary *> *)dictArray;

/// 刷新复用的卡片组件内容
///
/// @param element 可复用的组件实例
/// @param model 组件所绑定的model
/// @param layout 组件所在的卡片layout
/// @return 刷新后的复用组件实例
+ (UIView *)refreshElement:(UIView *)element byModel:(NSObject<TangramItemModelProtocol> *)model layout:(UIView<TangramLayoutProtocol> *)layout;

/// 新建卡片组件
///
/// @param model 组件所绑定的model
/// @param layout 组件所在的卡片layout
/// @return 新建组件实例
+ (UIView *)elementByModel:(NSObject<TangramItemModelProtocol> *)model layout:(UIView<TangramLayoutProtocol> *)layout;

/// rp单位转换
///
/// @param rpObject 原始rp值
/// @return rp对象转换后的数值
+ (float)floatValueByRPObject:(id)rpObject;

@end

NS_ASSUME_NONNULL_END
