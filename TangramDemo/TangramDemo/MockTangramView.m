//
//  MockTangramView.m
//  TangramDemo
//
//  Created by linjunbing on 2021/7/30.
//  Copyright © 2021 tmall. All rights reserved.
//

#import "MockTangramView.h"

#import <Tangram/ITangramRootView.h>
#import <Tangram/TangramLayoutProtocol.h>
#import <Tangram/TangramElementHeightProtocol.h>
#import <Tangram/TangramDefaultItemModel.h>
#import <Tangram/TangramDefaultDataSourceHelper.h>
#import <Tangram/ITangramEngine.h>

@interface MockTangramView ()<TangramViewDatasource, UIScrollViewDelegate>

@property (nonatomic, strong) ITangramRootView *tangramView;
@property (nonatomic, strong) NSArray *layoutArray;
@property (nonatomic, copy) NSArray *privateDataSource;

@end

@implementation MockTangramView

- (instancetype)init {
    if (self = [super init]) {
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}


#pragma mark - public
- (ITangramRootView *)container {
    return self.tangramView;
}

- (void)render {
    [self.tangramView render];
}

- (void)reloadData {
    [self.tangramView reloadData];
}

- (void)reloadData:(NSArray *)dataSource {
    self.privateDataSource = dataSource;
    self.layoutArray = [TangramDefaultDataSourceHelper layoutsWithArray:dataSource];
    [self.tangramView reloadData];
}

#pragma mark - public

- (void)reloadLayoutWithModel:(TangramDefaultItemModel *)itemModel data:(NSDictionary *)newData {
    UIView<TangramLayoutProtocol> *targetLayout = [self findLayoutByModel:itemModel];
    [self updateLayout:targetLayout data:newData];
}

- (void)reloadLayoutWithItemType:(NSString *)itemType data:(NSDictionary *)newData {
    UIView<TangramLayoutProtocol> *targetLayout = [self findLayoutByType:itemType];
    [self updateLayout:targetLayout data:newData];
}


#pragma mark - private
- (UIView<TangramLayoutProtocol> *)findLayoutByModel:(TangramDefaultItemModel *)itemModel {
    if (!itemModel) { return nil; }
    
    UIView<TangramLayoutProtocol> *targetLayout = nil;
    for (UIView<TangramLayoutProtocol> *layoutItem in self.layoutArray) {
        TangramDefaultItemModel *model = layoutItem.itemModels.firstObject;
        // match model
        if (model == itemModel) {
            targetLayout = layoutItem;
            break;
        }
    }
    return targetLayout;
}

- (UIView<TangramLayoutProtocol> *)findLayoutByType:(NSString *)itemType {
    if (!itemType || itemType.length == 0) { return nil; }
    
    UIView<TangramLayoutProtocol> *targetLayout = nil;
    for (UIView<TangramLayoutProtocol> *layoutItem in self.layoutArray) {
        TangramDefaultItemModel *model = layoutItem.itemModels.firstObject;
        // match model
        if ([model.itemType isEqualToString:itemType]) {
            targetLayout = layoutItem;
            break;
        }
    }
    return targetLayout;
}

- (void)updateLayout:(UIView<TangramLayoutProtocol> *)layout data:(NSDictionary *)newData {
    if (!layout || !newData || newData.count == 0) {
        return;
    }
    
    TangramDefaultItemModel *model = layout.itemModels.firstObject;
    
    // update data
    for (NSString *dictKey in newData.allKeys) {
        [model setBizValue:newData[dictKey] forKey:dictKey];
    }
    
    // update height
    Class clazz = NSClassFromString(model.linkElementName);
    if ([clazz conformsToProtocol:@protocol(TangramElementHeightProtocol)]) {
        Class<TangramElementHeightProtocol> elementClass = NSClassFromString(model.linkElementName);
        
        if ([clazz instanceMethodForSelector:@selector(heightByModel:)]) {
            model.heightFromElement = [elementClass heightByModel:model];
        }
    }
    
    [self.tangramView reloadLayout:layout];
}


- (void)setScrollViewDelegate:(id<UIScrollViewDelegate>)scrollViewDelegate {
    if (_scrollViewDelegate != scrollViewDelegate) {
        _scrollViewDelegate = scrollViewDelegate;
        self.tangramView.delegate = scrollViewDelegate;
    }
}


#pragma mark - private
- (void)setupSubviews {
    self.backgroundColor = UIColor.whiteColor;
    [self addSubview:self.tangramView];
    self.tangramView.frame = self.bounds;
}

#pragma mark - TangramViewDatasource
- (NSUInteger)numberOfLayoutsInTangramView:(TangramView *)view {
    return self.layoutArray.count;
}

- (UIView<TangramLayoutProtocol> *)layoutInTangramView:(TangramView *)view atIndex:(NSUInteger)index {
    return [self.layoutArray objectAtIndex:index];
}

- (NSUInteger)numberOfItemsInTangramView:(TangramView *)view forLayout:(UIView<TangramLayoutProtocol> *)layout {
    return layout.itemModels.count;
}

- (NSObject<TangramItemModelProtocol> *)itemModelInTangramView:(TangramView *)view forLayout:(UIView<TangramLayoutProtocol> *)layout atIndex:(NSUInteger)index {
    id<TangramItemModelProtocol> model = [layout.itemModels objectAtIndex:index];
    return model;
}

- (UIView *)itemInTangramView:(TangramView *)view withModel:(NSObject<TangramItemModelProtocol> *)model forLayout:(UIView<TangramLayoutProtocol> *)layout atIndex:(NSUInteger)index {
    
    UIView *reuseableView = [view dequeueReusableItemWithIdentifier:model.reuseIdentifier];
    if ([self.loadDataDelegate respondsToSelector:@selector(itemInTangramView:withModel:forLayout:)]) {
        reuseableView = [self.loadDataDelegate itemInTangramView:view withModel:model forLayout:layout];
    } else {
        if (reuseableView) {
            reuseableView = [ITangramEngine refreshElement:reuseableView byModel:model layout:layout];
        } else {
            reuseableView =  [ITangramEngine elementByModel:model layout:layout];
        }
    }
    return reuseableView;
}

- (void)tangramView:(ITangramRootView *)tangramView didLoadFirstRenderData:(NSArray *)data {
    if (tangramView == self.tangramView) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf reloadData:data];
        });
    }
}

#pragma mark - getter & setter

- (void)setContentInset:(UIEdgeInsets)contentInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_contentInset, contentInset)) {
        _contentInset = contentInset;
        self.tangramView.contentInset = contentInset;
    }
}

- (void)setLoadDataDelegate:(id<ITangramViewLoadProtocol>)loadDataDelegate {
    if (_loadDataDelegate != loadDataDelegate) {
        _loadDataDelegate = loadDataDelegate;
        self.tangramView.loadDelegate = loadDataDelegate;
    }
}

- (ITangramRootView *)tangramView {
    if (!_tangramView) {
        _tangramView = [[ITangramRootView alloc]init];
        _tangramView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tangramView.dataSource = self;
        _tangramView.hostInstance = self;
    }
    return _tangramView;
}

@end

