//
//  AppleDevice.m
//  AppleDevices
//
//  Created by 溪枫狼 on 2021/4/29.
//

#import "AppleDevice.h"
#import <sys/utsname.h>

inline UIWindow * KEY_WINDOW(void) {
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


@implementation AppleDevice

static NSString * jk_deviceModel;
+ (NSString *)currentDeviceName {
    if (!jk_deviceModel) {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString * machine = [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding];
        jk_deviceModel = [self appraiseAppleDeviceWithMachineNumber:machine];
    }
    return jk_deviceModel;
}

+ (BOOL)isNotchDesignStyle {
    BOOL notch = [self.currentDeviceName hasPrefix:@"iPhone X"] || [self.currentDeviceName hasPrefix:@"iPhone 11"] || [self.currentDeviceName hasPrefix:@"iPhone 12"];
    if (notch) return true;
    
    if (@available(iOS 11.0, *)) {
        if (@available(iOS 13.0, *)) {
            CGFloat statusBarHeight = CGRectGetHeight(KEY_WINDOW().windowScene.statusBarManager.statusBarFrame);
            return statusBarHeight > 43.f;
        } else {
            CGFloat topPadding = KEY_WINDOW().safeAreaInsets.top;
            return topPadding > 20;
        }
    } else {
        return false;
    }
}


// ===============================================================================


/// https://www.theiphonewiki.com/wiki/Models
+ (NSString *)appraiseAppleDeviceWithMachineNumber:(NSString *)machineNumber {
#if TARGET_IPHONE_SIMULATOR
    /// the machineNumber is i386 / x86_64 / arm64 .
    return @"Xcode Simulator";
#endif
    
    if ([machineNumber hasPrefix:@"iPhone"]) {
        return [self appraiseiPhoneModelWithMachineNumber:machineNumber];
    }
    
    if ([machineNumber hasPrefix:@"iPad"]) {
        return [self appraiseiPadModelWithMachineNumber:machineNumber];
    }
    
    if ([machineNumber hasPrefix:@"Apple TV"]) {
        return [self appraiseTVModelWithMachineNumber:machineNumber];
    }
    
    if ([machineNumber hasPrefix:@"Watch"]) {
        return [self appraiseWatchModelWithMachineNumber:machineNumber];
    }
    
    if ([machineNumber hasPrefix:@"iPod"]) {
        return [self appraiseiPodModelWithMachineNumber:machineNumber];
    }
    
    return machineNumber;
}

+ (NSString *)appraiseiPhoneModelWithMachineNumber:(NSString *)machineNumber {
    NSDictionary * const devices = @{
        @"iPhone13,4":@"iPhone 12 Pro Max",
        @"iPhone13,3":@"iPhone 12 Pro",
        @"iPhone13,2":@"iPhone 12",
        @"iPhone13,1":@"iPhone 12 mini",
        
        @"iPhone12,8":@"iPhone SE (2nd)",
        @"iPhone12,5":@"iPhone 11 Pro Max",
        @"iPhone12,3":@"iPhone 11 Pro",
        @"iPhone12,1":@"iPhone 11",
        
        @"iPhone11,8":@"iPhone XR",
        @"iPhone11,6":@"iPhone XS Max",
        @"iPhone11,4":@"iPhone XS Max",
        @"iPhone11,2":@"iPhone XS",
        
        @"iPhone10,6":@"iPhone X",
        @"iPhone10,3":@"iPhone X",

        @"iPhone10,5":@"iPhone 8 Plus",
        @"iPhone10,4":@"iPhone 8",
        @"iPhone10,2":@"iPhone 8 Plus",
        @"iPhone10,1":@"iPhone 8",
        
        @"iPhone9,4":@"iPhone 7 Plus",
        @"iPhone9,3":@"iPhone 7",
        @"iPhone9,2":@"iPhone 7 Plus",
        @"iPhone9,1":@"iPhone 7",
        
        @"iPhone8,4":@"iPhone SE",
        @"iPhone8,2":@"iPhone 6s Plus",
        @"iPhone8,1":@"iPhone 6s",

        @"iPhone7,2":@"iPhone 6",
        @"iPhone7,1":@"iPhone 6 Plus",
        
        @"iPhone6,2":@"iPhone 5s",
        @"iPhone6,1":@"iPhone 5s",
        
        @"iPhone5,4":@"iPhone 5c",
        @"iPhone5,3":@"iPhone 5c",
        @"iPhone5,2":@"iPhone 5",
        @"iPhone5,1":@"iPhone 5",
        
        @"iPhone4,1":@"iPhone 4S",
        
        @"iPhone3,3":@"iPhone 4",
        @"iPhone3,2":@"iPhone 4",
        @"iPhone3,1":@"iPhone 4",

        @"iPhone2,1":@"iPhone 3GS",
        
        @"iPhone1,2":@"iPhone 3G",
        @"iPhone1,1":@"iPhone",
    };
    return devices[machineNumber] ?: machineNumber;
}

+ (NSString *)appraiseiPadModelWithMachineNumber:(NSString *)machineNumber {
    NSDictionary * const devices = @{
        /// iPad Air
        @"iPad13,2":@"iPad Air (4th)",
        @"iPad13,1":@"iPad Air (4th)",
        
        @"iPad11,4":@"iPad Air (3rd)",
        @"iPad11,3":@"iPad Air (3rd)",
        
        @"iPad5,4":@"iPad Air 2",
        @"iPad5,3":@"iPad Air 2",
        
        @"iPad4,3":@"iPad Air",
        @"iPad4,2":@"iPad Air",
        @"iPad4,1":@"iPad Air",
        
        /// iPad
        @"iPad11,7":@"iPad (8th)",
        @"iPad11,6":@"iPad (8th)",
        
        @"iPad7,12":@"iPad (7th)",
        @"iPad7,11":@"iPad (7th)",
        
        @"iPad7,6":@"iPad (6th)",
        @"iPad7,5":@"iPad (6th)",
        
        @"iPad6,12":@"iPad (5th)",
        @"iPad6,11":@"iPad (5th)",
        
        @"iPad3,6":@"iPad (4th)",
        @"iPad3,5":@"iPad (4th)",
        @"iPad3,4":@"iPad (4th)",
        
        @"iPad3,3":@"iPad (3rd)",
        @"iPad3,2":@"iPad (3rd)",
        @"iPad3,1":@"iPad (3rd)",
        
        @"iPad2,4":@"iPad 2",
        @"iPad2,3":@"iPad 2",
        @"iPad2,2":@"iPad 2",
        @"iPad2,1":@"iPad 2",
        
        @"iPad1,1":@"iPad",
        
        
        /// iPad Pro
        @"iPad13,11":@"iPad Pro (12.9-inch) (5th)",
        @"iPad13,10":@"iPad Pro (12.9-inch) (5th)",
        @"iPad13,9":@"iPad Pro (12.9-inch) (5th)",
        @"iPad13,8":@"iPad Pro (12.9-inch) (5th)",
        
        @"iPad13,7":@"iPad Pro (11-inch) (3rd)",
        @"iPad13,6":@"iPad Pro (11-inch) (3rd)",
        @"iPad13,5":@"iPad Pro (11-inch) (3rd)",
        @"iPad13,4":@"iPad Pro (11-inch) (3rd)",
        
        @"iPad8,12":@"iPad Pro (12.9-inch) (4th)",
        @"iPad8,11":@"iPad Pro (12.9-inch) (4th)",
        
        @"iPad8,10":@"iPad Pro (11-inch) (2nd)",
        @"iPad8,9":@"iPad Pro (11-inch) (2nd)",
        
        @"iPad8,8":@"iPad Pro (12.9-inch) (3rd)",
        @"iPad8,7":@"iPad Pro (12.9-inch) (3rd)",
        @"iPad8,6":@"iPad Pro (12.9-inch) (3rd)",
        @"iPad8,5":@"iPad Pro (12.9-inch) (3rd)",
        
        @"iPad8,4":@"iPad Pro (11-inch)",
        @"iPad8,3":@"iPad Pro (11-inch)",
        @"iPad8,2":@"iPad Pro (11-inch)",
        @"iPad8,1":@"iPad Pro (11-inch)",
        
        @"iPad7,4":@"iPad Pro (10.5-inch)",
        @"iPad7,3":@"iPad Pro (10.5-inch)",
        
        @"iPad7,2":@"iPad Pro (12.9-inch) (2nd)",
        @"iPad7,1":@"iPad Pro (12.9-inch) (2nd)",
        
        @"iPad6,8":@"iPad Pro (12.9-inch)",
        @"iPad6,7":@"iPad Pro (12.9-inch)",
        @"iPad6,4":@"iPad Pro (9.7-inch)",
        @"iPad6,3":@"iPad Pro (9.7-inch)",
        
        
        /// iPad Mini
        @"iPad11,2":@"iPad Mini (5th)",
        @"iPad11,1":@"iPad Mini (5th)",
        
        @"iPad5,2":@"iPad Mini 4",
        @"iPad5,1":@"iPad Mini 4",
        
        @"iPad4,9":@"iPad Mini 3",
        @"iPad4,8":@"iPad Mini 3",
        @"iPad4,7":@"iPad Mini 3",
        
        @"iPad4,6":@"iPad Mini 2",
        @"iPad4,5":@"iPad Mini 2",
        @"iPad4,4":@"iPad Mini 2",
        
        @"iPad2,7":@"iPad Mini",
        @"iPad2,6":@"iPad Mini",
        @"iPad2,5":@"iPad Mini",
    };
    return devices[machineNumber] ?: machineNumber;
}

+ (NSString *)appraiseTVModelWithMachineNumber:(NSString *)machineNumber {
    NSDictionary * const devices = @{
        @"AppleTV11,1":@"Apple TV 4K (2nd)",
        @"AppleTV6,2":@"Apple TV 4K",
        
        @"AppleTV5,3":@"Apple TV (4th)",
        
        @"AppleTV3,2":@"Apple TV (3rd)",
        @"AppleTV3,1":@"Apple TV (3rd)",
        
        @"AppleTV2,1":@"Apple TV (2nd)",
        @"AppleTV1,1":@"Apple TV (1st)",
    };
    return devices[machineNumber] ?: machineNumber;
}

+ (NSString *)appraiseWatchModelWithMachineNumber:(NSString *)machineNumber {
    NSDictionary * const devices = @{
        @"Watch6,4":@"Apple Watch Series 6",
        @"Watch6,3":@"Apple Watch Series 6",
        @"Watch6,2":@"Apple Watch Series 6",
        @"Watch6,1":@"Apple Watch Series 6",
        
        @"Watch5,12":@"Apple Watch SE",
        @"Watch5,11":@"Apple Watch SE",
        @"Watch5,10":@"Apple Watch SE",
        @"Watch5,9":@"Apple Watch SE",
        
        @"Watch5,4":@"Apple Watch Series 5",
        @"Watch5,3":@"Apple Watch Series 5",
        @"Watch5,2":@"Apple Watch Series 5",
        @"Watch5,1":@"Apple Watch Series 5",
        
        @"Watch4,4":@"Apple Watch Series 4",
        @"Watch4,3":@"Apple Watch Series 4",
        @"Watch4,2":@"Apple Watch Series 4",
        @"Watch4,1":@"Apple Watch Series 4",
        
        @"Watch3,4":@"Apple Watch Series 3",
        @"Watch3,3":@"Apple Watch Series 3",
        @"Watch3,2":@"Apple Watch Series 3",
        @"Watch3,1":@"Apple Watch Series 3",
        
        @"Watch2,4":@"Apple Watch Series 2",
        @"Watch2,3":@"Apple Watch Series 2",
        
        @"Watch2,7":@"Apple Watch Series 1",
        @"Watch2,6":@"Apple Watch Series 1",
        
        @"Watch1,2":@"Apple Watch (1st)",
        @"Watch1,1":@"Apple Watch (1st)",
    };
    return devices[machineNumber] ?: machineNumber;
}

+ (NSString *)appraiseiPodModelWithMachineNumber:(NSString *)machineNumber {
    NSDictionary * const devices = @{
        @"iPod9,1":@"iPod touch (7th)",
        @"iPod7,1":@"iPod touch (6th)",
        @"iPod5,1":@"iPod touch (5th)",
        @"iPod4,1":@"iPod touch (4th)",
        @"iPod3,1":@"iPod touch (3rd)",
        @"iPod2,1":@"iPod touch (2nd)",
        @"iPod1,1":@"iPod touch",
    };
    return devices[machineNumber] ?: machineNumber;
}


@end
