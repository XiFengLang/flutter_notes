[TOC]

# AppleDevices

识别当前的苹果设备型号 -（Identify current Apple product model.）

**Support**

- [x] iPhone
- [x] iPad
- [x] Apple TV
- [x] Apple Watch
- [x] iPod touch

## 使用 & Usage

####  NSString * currentDeviceName

> * 识别当前设备型号
> * Identify current Apple product model with machine model, eg: iPhone 11, iPad Pro (11-inch).

```C
@property (class, nonatomic, copy, readonly) NSString * currentDeviceName;

AppleDevice.currentDeviceName   // iPhone 11
```

#### BOOL isNotchDesignStyle

> * 判断是不是刘海屏机型，支持模拟器
> * iPhone device with a notch design style, the notch design style is started with the iPhone X, and Xcode simulator is supported.


```C
@property (class, nonatomic, assign, readonly) BOOL isNotchDesignStyle;

AppleDevice.isNotchDesignStyle  // true
```


## 更新记录 & Change Log

- 2021-4-29 `...`

## 已适配机型 & Supported Devices

### iPhone


- [x] iPhone 12 Pro Max
- [x] iPhone 12 Pro
- [x] iPhone 12
- [x] iPhone 12 mini
- [x] iPhone SE (2nd)
- [x] iPhone 11 Pro Max
- [x] iPhone 11 Pro
- [x] iPhone 11
- [x] iPhone XR
- [x] iPhone XS Max
- [x] iPhone XS
- [x] iPhone X
- [x] iPhone 8 Plus
- [x] iPhone 8
- [x] iPhone 7 Plus
- [x] iPhone 7
- [x] iPhone SE
- [x] iPhone 6s Plus
- [x] iPhone 6s
- [x] iPhone 6
- [x] iPhone 6 Plus
- [x] iPhone 5s
- [x] iPhone 5c
- [x] iPhone 5
- [x] iPhone 4S


### iPad


- [x] iPad Air (4th)
- [x] iPad Air (3rd)
- [x] iPad Air 2
- [x] iPad Air
- [x] iPad (8th)
- [x] iPad (7th)
- [x] iPad (6th)
- [x] iPad (5th)
- [x] iPad (4th)
- [x] iPad (3rd)
- [x] iPad 2
- [x] iPad
- [x] iPad Pro (12.9-inch) (5th)
- [x] iPad Pro (11-inch) (3rd)
- [x] iPad Pro (12.9-inch) (4th)
- [x] iPad Pro (11-inch) (2nd)
- [x] iPad Pro (12.9-inch) (3rd)
- [x] iPad Pro (11-inch)
- [x] iPad Pro (10.5-inch)
- [x] iPad Pro (12.9-inch) (2nd)
- [x] iPad Pro (12.9-inch)
- [x] iPad Pro (9.7-inch)
- [x] iPad Mini (5th)
- [x] iPad Mini 4
- [x] iPad Mini 3
- [x] iPad Mini 2
- [x] iPad Mini


### Apple TV


- [x] Apple TV 4K (2nd)
- [x] Apple TV 4K
- [x] Apple TV (4th)
- [x] Apple TV (3rd)
- [x] Apple TV (2nd)
- [x] Apple TV (1st)


### Apple Watch


- [x] Apple Watch Series 6
- [x] Apple Watch SE
- [x] Apple Watch Series 5
- [x] Apple Watch Series 4
- [x] Apple Watch Series 3
- [x] Apple Watch Series 2
- [x] Apple Watch Series 1
- [x] Apple Watch (1st)



### iPod touch


- [x] iPod touch (7th)
- [x] iPod touch (6th)
- [x] iPod touch (5th)
- [x] iPod touch (4th)
- [x] iPod touch (3rd)
- [x] iPod touch (2nd)
- [x] iPod touch

## 参考 & Reference

* [https://www.theiphonewiki.com/wiki/Models](https://www.theiphonewiki.com/wiki/Models)
* [List of iOS and iPadOS devices](https://en.wikipedia.org/wiki/List_of_iOS_and_iPadOS_devices)
* [Identify your iPhone model](https://support.apple.com/en-us/HT201296)