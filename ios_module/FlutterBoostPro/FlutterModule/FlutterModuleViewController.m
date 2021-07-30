//
//  FlutterModuleViewController.m
//  FlutterBoostPro
//
//  Created by JK on 2021/6/10.
//

#import "FlutterModuleViewController.h"


@interface FlutterModuleViewController ()

@property (nonatomic, strong) NSMutableDictionary * params;

@end

@implementation FlutterModuleViewController


- (instancetype)initWithRoute:(NSString *)route params:(NSDictionary *)params {
    if (self = [super init]) {
        self.route = SafeString(route);
        self.params = SafeMutDictionary(params);
    }return self;
}

- (void)didInit {
    [super didInit];
    /// 因为继承BasicViewController，导致Flutter控制不了native的statusBarStyle
    /// 所以这里由初始参数控制，不随默认的
    if (self.params[kStatusBarStyle]) {
        [self resetStatusBarStyle:[self.params[kStatusBarStyle] integerValue]];
        [self.params removeObjectForKey:kStatusBarStyle];
    }
    
    _flutterContainer = [[FBFlutterViewContainer alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /// 隐藏系统自带的导航栏，由Flutter侧实现
    self.fd_prefersNavigationBarHidden = true;
    
    /// FDFullscreenPopGesture的全屏侧滑手势优先于Flutter页面的手势
    /// 如果Flutter页面是类似PageView的结构，就会导致Flutter页面的右向滑动失效，并触发FDFullscreenPopGesture的侧滑返回
    if (self.params[kDisableFullscreenPopGesture]) {
        self.fd_interactivePopDisabled = [self.params[kDisableFullscreenPopGesture] boolValue];
        [self.params removeObjectForKey:kDisableFullscreenPopGesture];
    }
    
    /// 供子类重写 调用 `setName:(NSString *)name params:(NSDictionary *)params;`
    [self willMountFlutterContainer];
    
    self.flutterContainer.view.frame = self.view.bounds;
    [self.view insertSubview:self.flutterContainer.view atIndex:0];
    [self addChildViewController:self.flutterContainer];
    
    [self willLayoutFlutterContainer];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    /// MARK: 下面这行代码在这儿会触发2次notifyWillDealloc，会导致FlutterBoost出现异常
    /// 比如 NoSuchMethodError: The getter 'topPage' was called on null.
    /// [self.flutterContainer didMoveToParentViewController:parent];

    /// 下面只会触发一次notifyWillDealloc，正常
    if (parent == nil && self.flutterContainer.parentViewController) {
        [self.flutterContainer removeFromParentViewController];
    }
    [super didMoveToParentViewController:parent];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        /// MARK: 解决NavigationController嵌套CustomFlutterVC导致Flutter页面不释放的问题
        /// 原因是 'dismissViewControllerAnimated:completion:' 并不会触发 'didMoveToParentViewController:'方法
        /// FBFlutterViewContainer 由重写 'dismissViewControllerAnimated:completion:' 方法来移除Flutter页面
        /// 但如果FBFlutterVC又被嵌套在自定义的CustomFlutterVC里面，CustomFlutterVC就需要实现移除Flutter页面的逻辑
        /// 比如下面的嵌套层级，NavigationController是present出来的
        /// NavigationController ---root vc---> CustomFlutterVC --- add sub vc --->  FBFlutterVC --- add sub vc ---> FlutterVC
        
        [self didMoveToParentViewController:nil];
    }];
}


#pragma mark - Override

- (void)willMountFlutterContainer {
    if (IsNonempty(self.route)) {
        [self.flutterContainer setName:self.route uniqueId:nil params:self.params opaque:false];
    } else {
        NSAssert(false, @"参数异常");
    }
}

- (void)willLayoutFlutterContainer {
    [self.flutterContainer.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_offset(0);
    }];
}


@end

