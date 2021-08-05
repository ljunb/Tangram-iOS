//
//  ITangramEngine.m
//  Tangram
//
//  Created by linjunbing on 2021/7/29.
//

#import "ITangramEngine.h"
#import <TMUtils/TMUtils.h>
#import <VirtualView/VVTemplateManager.h>
#import "TangramBus.h"
#import "TangramDefaultItemModelFactory.h"
#import "TangramDefaultDataSourceHelper.h"
#import "TangramLayoutProtocol.h"

#import "ITDefines.h"
#import "ITangramDownloader.h"

@interface ITangramEngine ()

@property (nonatomic, strong) NSMutableArray *privateTangramComponents;

@property (nonatomic, strong) NSMutableDictionary *localComponentDict;
@property (nonatomic, strong) NSMutableDictionary *componentBase64Dict;

@property (nonatomic, assign, getter=isLoadedXML) BOOL loadedXML;
@property (nonatomic, assign) BOOL isExistsTangramComponents;

@end

@implementation ITangramEngine

+ (instancetype)sharedEngine {
    static ITangramEngine *_engine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _engine = [[ITangramEngine alloc] init];
    });
    return _engine;
}

- (instancetype)init {
    if (self = [super init]) {
        _isExistsTangramComponents = [ITangramDownloader isExistsTangramComponents];
        if (!self.isLoadedXML) {
            [self loadAllComponentNames];
            [self registerAllVVComponents];
            self.loadedXML = YES;
        }
    }
    return self;
}


#pragma mark - public
- (void)addElementClassMap:(NSDictionary *)elementClassMap {
    if (!elementClassMap || elementClassMap.count == 0) {
        return;
    }
    
    for (NSString *typeKey in elementClassMap.allKeys) {
        id element = elementClassMap[typeKey];
        NSString *className;
        
        if ([element isKindOfClass:[NSString class]]) {
            className = (NSString *)element;
        } else {
            className = NSStringFromClass(element);
        }
        
        if ([TangramDefaultItemModelFactory isTypeRegisted:className]) {
            continue;
        }
        if (className && className.length > 0) {
            [self.privateTangramComponents addObject:className];
            [TangramDefaultItemModelFactory registElementType:typeKey className:className];
        } else {
            NSLog(@"注册组件 %@ 失败！", typeKey);
        }
    }
}

+ (NSArray<UIView<TangramLayoutProtocol> *> *)layoutsWithArray:(NSArray<NSDictionary *> *)dictArray {
    ITangramEngine *engine = [ITangramEngine sharedEngine];
    return [TangramDefaultDataSourceHelper layoutsWithArray:dictArray tangramBus:engine.tangramBus];
}

+ (UIView *)refreshElement:(UIView *)element byModel:(NSObject<TangramItemModelProtocol> *)model layout:(UIView<TangramLayoutProtocol> *)layout {
    ITangramEngine *engine = [ITangramEngine sharedEngine];
    return [TangramDefaultDataSourceHelper refreshElement:element byModel:model layout:layout tangramBus:engine.tangramBus];
}

+ (UIView *)elementByModel:(NSObject<TangramItemModelProtocol> *)model layout:(UIView<TangramLayoutProtocol> *)layout {
    ITangramEngine *engine = [ITangramEngine sharedEngine];
    return [TangramDefaultDataSourceHelper elementByModel:model layout:layout tangramBus:engine.tangramBus];
}

+ (float)floatValueByRPObject:(id)rpObject {
    return [TangramDefaultDataSourceHelper floatValueByRPObject:rpObject];
}


#pragma mark - private
- (void)loadAllComponentNames {
    [self.localComponentDict removeAllObjects];
    // 文件目录中有新的组件
    if (self.isExistsTangramComponents) {
        [self loadComponentNamesFromTangramFolder];
    } else {
        [self loadComponentNamesFromPlist];
    }
}

- (void)registerAllVVComponents {
    NSArray *elementList = [self.localComponentDict allKeys];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString *localTangramPath = [ITangramDownloader getTangramComponentsPath];
    
    for (NSString *templeteType in elementList) {
        NSString *localFileName = [self.localComponentDict tm_stringForKey:templeteType];
        
        // 如已经下载了Tangram组件，则用最新的
        if (self.isExistsTangramComponents) {
            NSString* localPath = [localTangramPath stringByAppendingPathComponent:[localFileName stringByAppendingString:@".out"]];
            
            if (localFileName.length > 0 && localPath.length > 0 && [fileManager fileExistsAtPath:localPath]) {
                NSLog(@"加载文件目录组件模板 filePath: %@ type: %@", localPath, templeteType);
                
                [[VVTemplateManager sharedManager] loadTemplateFileAsync:localPath forType:templeteType completion:nil];
            }
        } else {
            // assert base64版本
            NSString *localTemplateBase64 = [self.componentBase64Dict tm_stringForKey:templeteType];
            
            if (localFileName.length > 0 || localTemplateBase64.length > 0) {
                NSLog(@"加载assert目录组件模板 templateType %@", templeteType);
                
                [self loadDynamicTemplateWithBase64String:localTemplateBase64 templateType:templeteType];
            }
        }
    }
}

- (void)loadComponentNamesFromTangramFolder {
    NSString *tangramPath = [ITangramDownloader getTangramComponentsPath];
    
    NSError *error;
    NSArray *componentNames = [NSFileManager.defaultManager contentsOfDirectoryAtPath:tangramPath error:&error];
    if (error) {
        return;
    }
    
    for (int i = 0; i < componentNames.count; i++) {
        NSString *cmpFullName = componentNames[i];
        
        NSString *cmpName = [[cmpFullName componentsSeparatedByString:@".out"] firstObject];
        if (cmpName.length == 0) {
            continue;
        }
        // 只设置组件类型
        [self.localComponentDict tm_safeSetObject:cmpName forKey:cmpName];
    }
}

- (void)loadComponentNamesFromPlist {
    NSString *vvElementMapPath = [[NSBundle mainBundle] pathForResource:@"TangramKitVVElementTypeMap" ofType:@"plist"];
    NSArray *vvElementArrayFromPlist = [NSArray arrayWithContentsOfFile:vvElementMapPath];
    
    for (NSDictionary *dict in vvElementArrayFromPlist) {
        NSString *key = [dict tm_stringForKey:@"type"];
        if (key.length == 0) {
            continue;
        }
        NSString *fileName = [dict tm_stringForKey:@"fileName"];
        NSString *base64 = [dict tm_stringForKey:@"base64"];
        
        if (fileName.length > 0) {
            [self.localComponentDict tm_safeSetObject:fileName forKey:key];
        }
        if (base64.length > 0) {
            [self.componentBase64Dict tm_safeSetObject:base64 forKey:key];
        }
    }
}

- (BOOL)loadDynamicTemplateWithBase64String:(NSString *)cmpBase64Str templateType:(NSString *)type {
    NSAssert(cmpBase64Str && cmpBase64Str.length > 0, @"template xml base64 string couldn't be nil or empty!");
    NSAssert(type && type.length > 0, @"template type couldn't be nil or empty!");

    // 之前已经加载过了这个type
    if ([[VVTemplateManager sharedManager].loadedTypes containsObject:type]) {
        NSLog(@"this template type has been loaded!");
        return YES;
    }
    
    NSData *templateData = [[NSData alloc] initWithBase64EncodedString:cmpBase64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!templateData) {
        NSLog(@"load template data error!");
        return NO;
    }
    
    VVVersionModel *model = [[VVTemplateManager sharedManager] loadTemplateData:templateData forType:type];
    return model != nil;
}


#pragma mark - public
- (NSArray<NSString *> *)vvComponents {
    return [self.localComponentDict.allKeys copy];
}

- (NSArray<NSString *> *)tangramComponents {
    return [self.privateTangramComponents copy];
}


#pragma mark - getter
- (NSMutableDictionary *)localComponentDict {
    if (!_localComponentDict) {
        _localComponentDict = [NSMutableDictionary dictionary];
    }
    return _localComponentDict;
}

- (NSMutableDictionary *)componentBase64Dict {
    if (!_componentBase64Dict) {
        _componentBase64Dict = [NSMutableDictionary dictionary];
    }
    return _componentBase64Dict;
}

- (NSMutableArray *)privateTangramComponents {
    if (!_privateTangramComponents) {
        _privateTangramComponents = [NSMutableArray array];
    }
    return _privateTangramComponents;
}

- (TangramBus *)tangramBus {
    if (!_tangramBus) {
        _tangramBus = [[TangramBus alloc] init];
    }
    return _tangramBus;
}

@end
