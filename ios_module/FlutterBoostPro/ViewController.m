//
//  ViewController.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "ViewController.h"
#import "NativeViewController.h"
#import "FlutterModuleAgent.h"



@interface ViewController ()

@property (nonatomic, assign) NSInteger index;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Native Page";
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"present search" style:(UIBarButtonItemStylePlain) target:self action:@selector(presentSearchPage)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"push search" style:(UIBarButtonItemStylePlain) target:self action:@selector(pushSearchPage)];
    
    

    
    if (@available(iOS 13.0, *)) {
        var system = [UIButton jk_buttonWithFrame:CGRectMake(0, 150, 150, 40) titleColor:UIColor.whiteColor title:@"System"];
        system.jk_font(PingFangMediumFont(15)).jk_backgroundColor(UIColor.purpleColor).jk_cornrRadius(4);
        [system addTarget:self action:@selector(setSystemMode) forControlEvents:(UIControlEventTouchUpInside)];
        system.jk_centerX = self.view.jk_centerX;
        [self.view addSubview:system];
        
        var dark = [UIButton jk_buttonWithFrame:CGRectMake(0, 220, 150, 40) titleColor:UIColor.whiteColor title:@"DarkMode"];
        dark.jk_font(PingFangMediumFont(15)).jk_backgroundColor(UIColor.purpleColor).jk_cornrRadius(4);
        [dark addTarget:self action:@selector(setDarkMode) forControlEvents:(UIControlEventTouchUpInside)];
        dark.jk_centerX = self.view.jk_centerX;
        [self.view addSubview:dark];
        
        var light = [UIButton jk_buttonWithFrame:CGRectMake(0, 290, 150, 40) titleColor:UIColor.whiteColor title:@"LightMode"];
        light.jk_font(PingFangMediumFont(15)).jk_backgroundColor(UIColor.purpleColor).jk_cornrRadius(4);
        [light addTarget:self action:@selector(setLightMode) forControlEvents:(UIControlEventTouchUpInside)];
        light.jk_centerX = self.view.jk_centerX;
        [self.view addSubview:light];
    }
    
    
    
    var nativeButton = [UIButton jk_buttonWithFrame:CGRectMake(0, 400, 150, 40) titleColor:UIColor.whiteColor title:@"Push Native Page"];
    nativeButton.center = self.view.center;
    nativeButton.jk_font(PingFangMediumFont(15)).jk_backgroundColor(UIColor.purpleColor).jk_cornrRadius(4);
    [self.view addSubview:nativeButton];
    [nativeButton addTarget:self action:@selector(pushNativePage) forControlEvents:(UIControlEventTouchUpInside)];
}


- (void)presentSearchPage {
    self.index ++;
    [FlutterModuleNavigator present:@"search_page" arguments:@{@"index":@(self.index)}];
}

- (void)pushSearchPage {
    self.index ++;
    [FlutterModuleNavigator push:@"search_page" arguments:@{@"index":@(self.index)}];
}

- (void)pushNativePage {
    var vc = [[NativeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
}


- (void)setSystemMode API_AVAILABLE(ios(13.0), tvos(13.0)) {
    self.view.window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    [FlutterModuleAgent.shared preloadFlutterModuleAfterDelay:0.5];
}

- (void)setDarkMode API_AVAILABLE(ios(13.0), tvos(13.0)) {
    self.view.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    [FlutterModuleAgent.shared preloadFlutterModuleAfterDelay:0.5];
}

- (void)setLightMode API_AVAILABLE(ios(13.0), tvos(13.0)) {
    self.view.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    [FlutterModuleAgent.shared preloadFlutterModuleAfterDelay:0.5];
}



@end
