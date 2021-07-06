//
//  FlutterModuleNavigator.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "FlutterModuleNavigator.h"

@implementation FlutterModuleNavigator

+ (void)close:(NSString *)uniqueId {
    [FlutterBoost.instance close:uniqueId];
}

+ (void)push:(NSString *)url
   arguments:(NSDictionary *)arguments {
    [FlutterBoost.instance open:url arguments:arguments completion:^(BOOL finished) {
        
    }];
}

+ (void)push:(NSString *)url {
    [self push:url arguments:@{}];
}

+ (void)present:(NSString *)url
      arguments:(NSDictionary *)arguments {
    NSMutableDictionary * parameters = SafeMutDictionary(arguments);
    parameters[@"present"] = @(true);
    [FlutterBoost.instance open:url arguments:parameters completion:^(BOOL finished) {
        
    }];
}


+ (void)present:(NSString *)url {
    [self present:url arguments:@{}];
}


@end
