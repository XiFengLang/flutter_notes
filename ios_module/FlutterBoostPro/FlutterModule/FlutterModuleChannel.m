//
//  FlutterModuleChannel.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "FlutterModuleChannel.h"

@interface FlutterModuleChannel ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, FlutterMethodCallHandler>* interceptors;

@end


@implementation FlutterModuleChannel

- (NSMutableDictionary *)interceptors{
    if (!_interceptors) {
        _interceptors = [[NSMutableDictionary alloc]init];
    }return _interceptors;
}


+ (FlutterModuleChannel *)global {
    static FlutterModuleChannel * channel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channel = [[FlutterModuleChannel alloc] init];
    });
    return channel;
}



- (void)initMessageChannelWithEngine:(FlutterEngine *)engine {
    _channel = [FlutterMethodChannel methodChannelWithName:@"app_global_channel" binaryMessenger:engine.binaryMessenger];
    __weak typeof(self) weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        __strong typeof(weakSelf) self = weakSelf;
        
        /// 业务层注册的一些拦截器
        FlutterMethodCallHandler handler = [self.interceptors objectForKey:call.method];
        if (handler) {
            handler(call, result);
            return;
        }
        
        
        /// MARK: 实现一些通用的响应
        
        /// 磁盘总容量
        if ([call.method isEqualToString:@"total_disk_size"]) {
            var totalSpace = [self totalDiskSize];
            result([NSNumber numberWithUnsignedLongLong:totalSpace]);
        }
        /// 磁盘可用容量
        else if ([call.method isEqualToString:@"free_disk_size"]) {
            var freeSpace = [self freeDiskSize];
            result([NSNumber numberWithUnsignedLongLong:freeSpace]);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
}


- (void)addInterceptorForMethod:(NSString *)method received:(FlutterMethodCallHandler)received {
    if (method && received) {
        NSAssert(!self.interceptors[method], @"请勿重复注册");
        [self.interceptors setObject:received forKey:method];
    } else {
        NSAssert(false, @"搞啥呢");
    }
}

- (void)removeInterceptorForMethod:(NSString *)method {
    if (method) {
        [self.interceptors removeObjectForKey:method];
    }
}






- (unsigned long long)totalDiskSize {
    unsigned long long totalSpace = 0;
    if (@available(iOS 11.0, *)) {
        NSDictionary * resource = [[NSURL fileURLWithPath:NSHomeDirectory()] resourceValuesForKeys:@[NSURLVolumeTotalCapacityKey] error:nil];
        totalSpace = [[resource objectForKey:NSURLVolumeTotalCapacityKey] unsignedLongLongValue];
    } else {
        totalSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] unsignedLongLongValue];
    }
    return totalSpace/(1024*1024);
}

- (unsigned long long)freeDiskSize {
    unsigned long long freeSpace = 0;
    if (@available(iOS 11.0, *)) {
        /// NSURLVolumeAvailableCapacityKey, NSURLVolumeAvailableCapacityForImportantUsageKey, NSURLVolumeAvailableCapacityForOpportunisticUsageKey
        NSDictionary * resource = [[NSURL fileURLWithPath:NSHomeDirectory()] resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:nil];
        freeSpace = [[resource objectForKey:NSURLVolumeAvailableCapacityKey] unsignedLongLongValue];
    } else {
        freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
    }
    return freeSpace/(1024*1024);
}


@end

