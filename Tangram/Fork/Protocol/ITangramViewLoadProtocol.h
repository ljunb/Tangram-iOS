//
//  XTangramViewLoadProtocol.h
//  Tangram
//
//  Created by linjunbing on 2021/7/30.
//

#import <Foundation/Foundation.h>

@protocol TangramItemModelProtocol;
@protocol TangramLayoutProtocol;
@class TangramDefaultItemModel;
@class TangramView;
@class IVVBaseElement;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ITLayoutResponseBlock)(NSArray *response, BOOL isSuccess);

@protocol ITangramViewLoadProtocol <NSObject>

@required
/// 当前页面布局loadKey，暂时未使用，先返回页面唯一标识
- (NSString *)getLayoutLoadKey;

@required
/// 从本地缓存获取数据方法，必须实现的方法，业务方可以在此返回本地缓存或是保底的布局数据。
///
/// 如果getDataFromNetwork优先返回，将弃用该方法回调结果，不会触发结束回调；否则正常触发。
///
/// @param loadKey 页面loadKey，对应getLayoutLoadKey返回值
/// @param completion 结束回调，结果将是一个数组
- (void)getDataFromCache:(NSString *)loadKey completion:(ITLayoutResponseBlock)completion;

@required
/// 从网络获取数据方法，必须实现的方法，业务方可以在此发起网络请求，并返回对应的布局数据。
///
/// 如果getDataFromNetwork优先返回，将弃用本地结果，不会触发getDataFromNetwork结束回调。
///
/// @param loadKey 页面loadKey，对应getLayoutLoadKey返回值
/// @param completion 结束回调，结果将是一个数组
- (void)getDataFromNetwork:(NSString *)loadKey completion:(ITLayoutResponseBlock)completion;


#pragma mark - 组件异步加载相关
@optional

/// 当组件中设置了 load 属性时，通过该方法回调加载到的数据
///
/// @param loadKey 装载数据对应的key
/// @param originData 原始数据
/// @param completion 结束回调，参数为字典类型
- (void)asyncLoadJSONDataWithKey:(NSString *)loadKey
                         originData:(NSDictionary *)originData
                         completion:(void(^)(NSDictionary *resDict))completion;


#pragma mark - 组件点击相关
@optional
/// 组件点击回调
///
/// @param action 事件响应名称
/// @param reportKey 事件上报的key
/// @param originData 组件配置的原始数据源
- (void)virtualViewDidClickWithAction:(NSString *)action reportKey:(NSString *)reportKey originData:(NSDictionary *)originData;


#pragma mark - 组件数据源相关
@optional
/// 获取卡片中对应的组件实例
///
/// @param view TangramView实例本身
/// @param model 当前卡片所绑定的model
/// @param layout 当前卡片所在的布局layout
- (UIView *)itemInTangramView:(TangramView *)view withModel:(NSObject<TangramItemModelProtocol> *)model forLayout:(UIView<TangramLayoutProtocol> *)layout;


#pragma mark - 组件曝光相关
@optional
/// 组件已进入视图可见区域
///
/// @param element 组件对象
/// @param itemModel 组件绑定的数据model
- (void)element:(IVVBaseElement *)element didDisplayWithItemModel:(TangramDefaultItemModel *)itemModel;

@optional
/// 组件已进入视图可见区域
///
/// @param itemModel 组件绑定的数据model
- (void)elementDidDisplayWithItemModel:(TangramDefaultItemModel *)itemModel;

@optional
/// 组件已在视图不可见区域
///
/// @param element 组件对象
/// @param itemModel 组件绑定的数据model
- (void)element:(IVVBaseElement *)element didEndDisplayWithItemModel:(TangramDefaultItemModel *)itemModel;

@optional
/// 组件已在视图不可见区域
///
/// @param itemModel 组件绑定的数据model
- (void)elementDidEndDisplayWithItemModel:(TangramDefaultItemModel *)itemModel;


@end

NS_ASSUME_NONNULL_END
