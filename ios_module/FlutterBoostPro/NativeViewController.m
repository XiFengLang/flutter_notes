//
//  NativeViewController.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "NativeViewController.h"

@interface NativeViewController ()

@end

@implementation NativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"native page";
    
    var nativeButton = [UIButton jk_buttonWithFrame:CGRectMake(0, 0, 150, 40) titleColor:UIColor.whiteColor title:@"Push Native Page"];
    nativeButton.center = self.view.center;
    nativeButton.jk_font(PingFangMediumFont(15)).jk_backgroundColor(UIColor.purpleColor).jk_cornrRadius(4);
    [self.view addSubview:nativeButton];
    [nativeButton addTarget:self action:@selector(pushNativePage) forControlEvents:(UIControlEventTouchUpInside)];
}


- (void)pushNativePage {
    var vc = [[NativeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
}

@end
