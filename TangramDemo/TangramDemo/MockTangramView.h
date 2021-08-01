//
//  MockTangramView.h
//  TangramDemo
//
//  Created by linjunbing on 2021/7/30.
//  Copyright © 2021 tmall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Tangram/ITangramRootView.h>

@class TangramDefaultItemModel;

NS_ASSUME_NONNULL_BEGIN

@interface MockTangramView : UIView<ITangramViewHostProtocol>

@property (nonatomic, weak) id<UIScrollViewDelegate> scrollViewDelegate;

/// XTangramView 中 TangramView 的实例
@property (nonatomic, strong, readonly) ITangramRootView *container;
/// 设置 TangramView 实例内边距
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, weak) id<ITangramViewLoadProtocol> loadDataDelegate;

- (void)render;
- (void)reloadData;
- (void)reloadData:(NSArray *)dataSource;

- (void)reloadLayoutWithModel:(TangramDefaultItemModel *)itemModel data:(NSDictionary *)newData;
- (void)reloadLayoutWithItemType:(NSString *)itemType data:(NSDictionary *)newData;

@end

NS_ASSUME_NONNULL_END
