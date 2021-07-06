//
//  Func.h
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#ifndef Func_h
#define Func_h

#import <UIKit/UIKit.h>
#import <AppleDevices/AppleDevice.h>

#define var __auto_type
#define SafeBlockPerformer(blockFunc, ...) if(blockFunc != nil) blockFunc(__VA_ARGS__);




/// 16进制色值 --> UIColor，提示：不支持`0x00xxxxxx`格式的透明色，透明色请使用Color()
static inline UIColor * Color0x(long hexValue) {
    long hex = hexValue & 0xFFFFFFFF;
    int a = (0xff000000 & hex) >> 24;
    int r = (0x00ff0000 & hex) >> 16;
    int g = (0x0000ff00 & hex) >> 8;
    int b = (0x000000ff & hex) >> 0;
    if (hex <= 0xFFFFFF) {
        /// HEX (0x1A1A1A)
        return [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:1];
    } else {
        /// AHEX (0xFF1A1A1A)
        return [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:a/255.f];
    }
}

/// 16进制色值 --> UIColor，支持域hex <= 0xFFFFFF，不支持AHEX
static inline UIColor * Color0xA(long hexValue, CGFloat alpha) {
    long hex = hexValue & 0xFFFFFFFF;
    int r = (0x00ff0000 & hex) >> 16;
    int g = (0x0000ff00 & hex) >> 8;
    int b = (0x000000ff & hex) >> 0;
    if (hex > 0xFFFFFF) {
        NSLog(@"===============================⚠️start⚠️===============================");
        NSLog(@"\nPublicFunction Warning!!!  [ %s ]  -:unsupported color value -: 此函数不支持AHEX格式\n%@",__func__,NSThread.callStackSymbols);
        NSLog(@"===============================⚠️end⚠️===============================");
    }
    return [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:alpha];
}


static inline UIFont * PingFangRegularFont(CGFloat size) {
    return [UIFont fontWithName:@"PingFangSC-Regular" size:size];
}


static inline UIFont * PingFangMediumFont(CGFloat size) {
    return [UIFont fontWithName:@"PingFangSC-Medium" size:size];
}

static inline UIFont * PingFangSemiboldFont(CGFloat size) {
    return [UIFont fontWithName:@"PingFangSC-Semibold" size:size];
}


static inline UIWindow * KeyWindow(void) {
    NSArray <UIWindow *>* windows = [UIApplication sharedApplication].windows;
    __block UIWindow * visible = nil;
    [windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isKeyWindow && obj.isHidden == false) {
            visible = obj;
            *stop = true;
        }
    }];
    return visible ? visible : windows.lastObject;
}

static inline BOOL iPhoneX(void) {
    return AppleDevice.isNotchDesignStyle;
}



static inline NSString * SafeString(id obj) {
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj copy];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj stringValue];
    } else if (nil == obj || [NSNull null] == obj) {
        NSLog(@"==============================================");
        NSLog(@"JKPublicFunction Warning!!!   [ %s ]  obj为空",__func__);
        NSLog(@"==============================================\n.");
        return @"";
    }
    return [NSString stringWithFormat:@"%@",obj];
}


static inline NSArray * SafeArray(id obj) {
    if ([obj isKindOfClass:[NSArray class]]) {
        return [obj copy];
    } else if (nil == obj || [NSNull null] == obj) {
        NSLog(@"==============================================");
        NSLog(@"JKPublicFunction Warning!!!   [ %s ]  obj为空",__func__);
        NSLog(@"==============================================\n.");
        return @[];
    }
    return @[];
}


static inline NSMutableArray * SafeMutArray(id obj) {
    if ([obj isKindOfClass:[NSMutableArray class]]) {
        return [obj mutableCopy];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [[NSMutableArray alloc] initWithArray:obj];
    } else if (nil == obj || [NSNull null] == obj) {
        NSLog(@"==============================================");
        NSLog(@"JKPublicFunction Warning!!!   [ %s ]  obj为空",__func__);
        NSLog(@"==============================================\n.");
        return [[NSMutableArray alloc] init];
    }
    return [[NSMutableArray alloc] init];
}


static inline NSDictionary * SafeDictionary(id obj) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [obj copy];
    } else if (nil == obj || [NSNull null] == obj) {
        NSLog(@"==============================================");
        NSLog(@"JKPublicFunction Warning!!!   [ %s ]  obj为空",__func__);
        NSLog(@"==============================================\n.");
        return @{};
    }
    return @{};
}

static inline NSMutableDictionary * SafeMutDictionary(id obj) {
    if ([obj isKindOfClass:[NSMutableDictionary class]]) {
        return [obj mutableCopy];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return [[NSMutableDictionary alloc] initWithDictionary:obj];
    } else if (nil == obj || [NSNull null] == obj) {
        NSLog(@"==============================================");
        NSLog(@"JKPublicFunction Warning!!!   [ %s ]  obj为空",__func__);
        NSLog(@"==============================================\n.");
        return [[NSMutableDictionary alloc] init];
    }
    return [[NSMutableDictionary alloc] init];
}

static inline BOOL IsNonempty(NSObject *object) {
    if (!object) {
        return false;
    } else if ([object isEqual:[NSNull null]] || [object isKindOfClass:NSNull.class]) {
        return false;
    } else if ([object isKindOfClass:[NSString class]]) {
        return [(NSString *)object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [(NSArray *)object count];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)object count];
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [(NSSet *)object count];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return true;
    } else if ([object isKindOfClass:NSData.class]) {
        if ([(NSData *)object length] == 0) {
            return false;
        }
        BOOL isSpace = [(NSData *)object isEqualToData:[NSData dataWithBytes:" " length:1]];
        return !isSpace;
    }
    // 默认对象不为空
    return true;
}

#endif /* Func_h */
