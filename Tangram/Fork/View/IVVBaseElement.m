//
//  XPVVBaseElement.m
//  Tangram
//
//  Created by linjunbing on 2021/5/24.
//

#import "IVVBaseElement.h"
#import "VVTempleteManager.h"
#import "TangramEvent.h"
#import "UIView+Tangram.h"
#import <objc/runtime.h>
#import "TMLazyItemViewProtocol.h"

#import "ITDefines.h"
#import "ITangramRootView.h"

@implementation IVVBaseElement

+ (CGFloat)heightByModel:(TangramDefaultItemModel *)itemModel {
    VVViewContainer *container = [VVViewContainer viewContainerWithTemplateType:itemModel.type];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    container.clipsToBounds = YES;
    NSDictionary *bizDict = [itemModel privateOriginalDict];
    [container update:bizDict];
    CGSize size = [container estimatedSize:CGSizeMake(itemModel.modelRect.size.width, 1000)];
    return size.height;
}

- (void)virtualViewClickedWithAction:(NSString *)action andValue:(NSString *)value
{
    NSString *actualAction = value;
    if (actualAction.length <= 0) {
        actualAction = [self.tangramItemModel bizValueForKey:action];
    }

    if (self.tangramBus) {
        TangramEvent *event = [[TangramEvent alloc] initWithTopic:kXTangramVVAction
                                                  withTangramView:self.inTangramView
                                                 posterIdentifier:kXTangramVVPosterIdentifier
                                                        andPoster:self];
        [event setParam:action forKey:@"action"];
        [event setParam:self.tangramItemModel.privateOriginalDict forKey:@"originData"];
        
        [self.tangramBus postEvent:event];
    }
}


#pragma mark - TMLazyItemViewProtocol
- (void)mui_didEnterWithTimes:(NSUInteger)times {
    if (self.tangramViewLoadDelegate) {
        TangramDefaultItemModel *itemModel = self.tangramItemModel;
        if ([self.tangramViewLoadDelegate respondsToSelector:@selector(elementDidEndDisplayWithItemModel:)]) {
            [self.tangramViewLoadDelegate elementDidDisplayWithItemModel:itemModel];
        } else if ([self.tangramViewLoadDelegate respondsToSelector:@selector(element:didDisplayWithItemModel:)]) {
            [self.tangramViewLoadDelegate element:self didDisplayWithItemModel:itemModel];
        }
    }
}

- (void)mui_didLeave {
    if (self.tangramViewLoadDelegate) {
        TangramDefaultItemModel *itemModel = self.tangramItemModel;
        if ([self.tangramViewLoadDelegate respondsToSelector:@selector(elementDidEndDisplayWithItemModel:)]) {
            [self.tangramViewLoadDelegate elementDidEndDisplayWithItemModel:itemModel];
        } else if ([self.tangramViewLoadDelegate respondsToSelector:@selector(element:didEndDisplayWithItemModel:)]) {
            [self.tangramViewLoadDelegate element:self didEndDisplayWithItemModel:itemModel];
        }
    }
}

- (id<ITangramViewLoadProtocol>)tangramViewLoadDelegate {
    if ([self.inTangramView isKindOfClass:[ITangramRootView class]] ) {
        ITangramRootView *rootTangramView = (ITangramRootView *)self.inTangramView;
        return rootTangramView.loadDelegate;
    }
    return nil;
}


@end
