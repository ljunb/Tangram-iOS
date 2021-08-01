//
//  MockViewController.m
//  TangramDemo
//
//  Copyright (c) 2017-2018 Alibaba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MockViewController.h"
#import "MockTangramView.h"
#import <Tangram/TangramView.h>

#import <Tangram/ITangramEngine.h>
#import <Tangram/ITangramRootView.h>
#import <Tangram/TangramItemModelProtocol.h>


@interface MockViewController ()<ITangramViewLoadProtocol>

@property (nonatomic, strong) MockTangramView    *tangramView;


@end

@implementation MockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tangramView render];
}

- (void)getDataFromCache:(NSString *)loadKey completion:(ITLayoutResponseBlock)completion {
    NSString *mockDataString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Mock" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [mockDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
//    [NSThread sleepForTimeInterval:2];
    completion(result, YES);
}

- (void)getDataFromNetwork:(NSString *)loadKey completion:(ITLayoutResponseBlock)completion {
    NSString *mockDataString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MockFromNetwork" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [mockDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    [NSThread sleepForTimeInterval:2];
    completion(result, YES);
}

- (nonnull NSString *)getLayoutLoadKey {
    return @"MockViewController";
}

#pragma mark - XPTangramAsyncItemLoadDelegate
- (void)asyncLoadJSONDataWithKey:(NSString *)loadKey originData:(NSDictionary *)originData completion:(void (^)(NSDictionary * _Nonnull))completion {
    if ([loadKey isEqualToString:@"com.xxx.async_load.test1"]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [NSThread sleepForTimeInterval:1];
            
            completion(@{@"itemTitle": @"title from mock view controller"});
        });
    } else if ([loadKey isEqualToString:@""]) {
        
    }
}

- (void)virtualViewDidClickWithAction:(NSString *)action reportKey:(NSString *)reportKey originData:(NSDictionary *)originData {
    NSLog(@"virtual view did click : %@, reportKey: %@, originData: %@", action, reportKey, originData);
}

- (UIView *)itemInTangramView:(TangramView *)view withModel:(NSObject<TangramItemModelProtocol> *)model forLayout:(UIView<TangramLayoutProtocol> *)layout {
    UIView *reuseableView = [view dequeueReusableItemWithIdentifier:model.reuseIdentifier];
    view.backgroundColor = UIColor.clearColor;

    if (reuseableView) {
        reuseableView = [ITangramEngine refreshElement:reuseableView byModel:model layout:layout];
    } else {
        reuseableView =  [ITangramEngine elementByModel:model layout:layout];
    }

    return reuseableView;
}


#pragma mark - Getter
-(MockTangramView *)tangramView
{
    if (nil == _tangramView) {
        _tangramView = [[MockTangramView alloc]init];
        _tangramView.frame = self.view.bounds;
        _tangramView.loadDataDelegate = self;
        _tangramView.backgroundColor = UIColor.lightGrayColor;
        [self.view addSubview:_tangramView];
    }
    return _tangramView;
}


@end
