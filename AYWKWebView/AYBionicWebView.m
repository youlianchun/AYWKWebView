//
//  AYBionicWebView.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYBionicWebView.h"

#pragma mark -
#pragma mark - super
void aywkobjc_setAssociated(id target, SEL property, id value , BOOL retain);
id aywkobjc_getAssociated(id target, SEL property);
void aywkw_setAssociated(id target, NSString *propertyName, id value , BOOL retain);
id aywkw_getAssociated(id target, NSString *propertyName);
void aywkw_replaceMethod(Class class, SEL originSelector, SEL newSelector);

@interface AYWKWebView ()
@property (nonatomic, weak, readonly) UIScreenEdgePanGestureRecognizer *backNavigationGesture;
@property (nonatomic, weak, readonly) UIScreenEdgePanGestureRecognizer *forwardNavigationGesture;
@end

#pragma mark -
#pragma mark - AYBionicWebView
@interface AYBionicWebView ()
@property (nonatomic, weak) UIViewController *viewController;
@end

#if AYWKWebView_bionicEnabled
//为每个WKBackForwardListItem添加一个UINavigationBar属性（拥有各自导航条）
@interface WKBackForwardListItem (AYBionicWebView)
@property (nonatomic, strong) UINavigationBar *navigationBar;
-(void)navigationBarWithLeftItems:(NSArray<UIBarButtonItem*>*)leftItems rightItems:(NSArray<UIBarButtonItem*>*)rightItems;
@end
@implementation WKBackForwardListItem (AYBionicWebView)
-(UINavigationBar *)navigationBar {
    return aywkobjc_getAssociated(self, @selector(navigationBar));
}
-(void)setNavigationBar:(UINavigationBar *)navigationBar {
    aywkobjc_setAssociated(self, @selector(navigationBar), navigationBar, YES);
}
-(void)navigationBarWithLeftItems:(NSArray<UIBarButtonItem*>*)leftItems rightItems:(NSArray<UIBarButtonItem*>*)rightItems {
    UINavigationBar *navigationBar = [[UINavigationBar alloc] init];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:self.title];
    item.leftBarButtonItems = leftItems;
    item.rightBarButtonItems = rightItems;
    navigationBar.items = [NSArray arrayWithObject:item];
    self.navigationBar = navigationBar;
}
@end

static BOOL kTransition_ing = NO;//YES:转场正在执行
static BOOL kNavigationBarExist = NO;//YES:导航栏存在且显示
static NSUInteger const kTransitionTag = 110192312;//tag值，用于标记from、to转场试图superview

Class k_UIParallaxDimmingView_Class (){
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cls = NSClassFromString(@"_UIParallaxDimmingView");
    });
    return cls;
}

@implementation UIView (AYBionicWebView)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UIView class];
        aywkw_replaceMethod(class, @selector(addSubview:), @selector(bionic_addSubview:));
    });
}

-(void)bionic_addSubview:(UIView *)view {
    [self bionic_addSubview:view];
    if (kNavigationBarExist && kTransition_ing) {//转场开始时候对addSubview事件进行拦截
        if([self class] == [UIView class]) {
            [self addTransitionNavigationBarInViewIfNeeded:view];//如果可以，添加转场导航条
        }
        if ([self isKindOfClass:k_UIParallaxDimmingView_Class()]) {
            if ([view class] == [UIView class]) {
                UIView *v = aywkw_getAssociated(self, @"customBar");
                if (v) {//将customBar保持再最前端
                    [self bringSubviewToFront:v];
//                    aybw_setAssociated(self, @"customBar", nil, NO);//customBar 为week，可不需要
                }
            }
        }
    }
}

- (void)addTransitionNavigationBarInViewIfNeeded:(UIView*)view {
    if (self.tag == kTransitionTag) {
        if (view.subviews.count>0) {//场景特殊情况，（仅from、to视图都存在subviews）
            //每次专场 代码将自行两次，一次是from视图，一次是to视图，（其中一个仅是图像视图，一个包含WKScrollView视图）
            AYBionicWebView *webView = aywkw_getAssociated(self, @"rootWKWebView");
            if (webView) {
//                view.tag = 110;
                UIView *sView = view.subviews.firstObject;
                UIView *panelView = sView.clipsToBounds?view:sView;//视图层次结构导致，（app内部对View进行了完全复制，sView.clipsToBounds为场景特殊情况，用来做标记）
                BOOL isGoBack = NO;//YES 后退; NO 前进
                if (webView.forwardNavigationGesture.state == UIGestureRecognizerStateBegan) {
                    isGoBack = NO;
                }
                if (webView.backNavigationGesture.state == UIGestureRecognizerStateBegan) {
                    isGoBack = YES;
                }
                
                BOOL isFront;//YES 上层; NO 底层
                if ([sView isKindOfClass:k_UIParallaxDimmingView_Class()] && [sView.subviews.firstObject isKindOfClass:[UIImageView class]]) {//转场视图结构特性，为_UIParallaxDimmingView且第一个子视图是UIImageView时候是上层转场视图
                    UIImageView *imageView = sView.subviews.firstObject;//转场过程中的阴影imageView（丢改frame覆盖导航条区域）
                    CGRect frame = imageView.frame;
                    frame.origin.y -= 64;
                    frame.size.height += 64;
                    imageView.frame = frame;
                    isFront = YES;
                }else{
                    isFront = NO;
                }
                //获取当前转场视图（from 或 to）导航条
                WKBackForwardListItem *backForwardItem;
                if (isGoBack) {
                    if (isFront) {
                        backForwardItem = webView.backForwardList.currentItem;
                    }else{
                        backForwardItem = webView.backForwardList.backItem;
        //              UIImage* image = [self imageWithUIView:panelView];//获取转场视图中的图片视图image（上一页）
                    }
                }else{
                    if (isFront) {
                        backForwardItem = webView.backForwardList.forwardItem;
        //              UIImage* image = [self imageWithUIView:panelView];//获取转场视图中的图片视图image（前一页）
                    }else{
                        backForwardItem = webView.backForwardList.currentItem;
                    }
                }
                
                UINavigationBar * customBar = backForwardItem.navigationBar;
                
                UINavigationBar *originBar = webView.viewController.navigationController.navigationBar;
                if (!customBar) {
                    customBar = [[UINavigationBar alloc] init];
                    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:backForwardItem.title];
                    customBar.items = [NSArray arrayWithObject:item];
                    backForwardItem.navigationBar = customBar;
                }
                
                {//原本导航条样式复制到转场导航条上
                    if (customBar.barStyle != originBar.barStyle) {
                        customBar.barStyle = originBar.barStyle;
                    }
                    if (customBar.translucent != originBar.translucent) {
                        customBar.translucent = originBar.translucent;
                    }
                    if (![customBar.barTintColor isEqual:originBar.barTintColor]) {
                        customBar.barTintColor = originBar.barTintColor;
                    }
                    UIImage *backgroundImage = [originBar backgroundImageForBarMetrics:UIBarMetricsDefault];
                    
                    [customBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
                    [customBar setShadowImage:originBar.shadowImage];
                    
                    UIView *backgroundView = [originBar valueForKey:@"_backgroundView"];
                    CGRect rect = [backgroundView.superview convertRect:backgroundView.frame toView:self];
                    customBar.frame = rect;
                }
                aywkw_setAssociated(panelView, @"customBar", customBar, NO);//用于panelView addSubview 时候 customBar置前处理
                
                [panelView addSubview:customBar];//添加转场导航条
            }
        }
    }
}
//-(UIImage*)imageWithUIView:(UIView*)view{
//    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
//    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}
@end
#endif

@implementation AYBionicWebView

-(instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self customIntitialization];
    }
    return self;
}

- (void)customIntitialization {
    super.allowsLinkPreview = NO;
    super.allowsForwardNavigationGestures = NO;
    super.allowSelectionGestures = NO;
    super.allowLongPressGestures = NO;
}

-(UIViewController *)viewController {
    if (!_viewController) {
        id target=self;
        while (target) {
            target = ((UIResponder *)target).nextResponder;
            if ([target isKindOfClass:[UIViewController class]]) {
                break;
            }
        }
        _viewController = target;
    }
    return _viewController;
}

#if AYWKWebView_bionicEnabled
-(void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    if (kNavigationBarExist && (kTransition_ing || self.backNavigationGesture.state == UIGestureRecognizerStateBegan || self.forwardNavigationGesture.state == UIGestureRecognizerStateBegan)) {//可以使设置导航条跟随效果时候insertSubview了转场视图（导航条存在且正在显示，转场开始）
        view.tag = kTransitionTag;//为转场视图做标记
        aywkw_setAssociated(view, @"rootWKWebView", self, NO);//将self（WkWebView）给转场视图，后边获取导航栏需要
        self.viewController.navigationController.navigationBar.alpha = 0;//隐藏真实导航栏
    }
    [super insertSubview:view belowSubview:siblingSubview];
}

//WKNavigationDelegatePrivate 导航转场结束
- (void)_webViewDidEndNavigationGesture:(WKWebView *)webView withNavigationToBackForwardListItem:(WKBackForwardListItem *)item {//item 存在时候表示转场完成，item == nil 表示转场取消
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.navigationDelegate performSelector:_cmd withObject:webView withObject:item];
#pragma clang diagnostic pop
    kTransition_ing = NO;
    if (item) {
        self.viewController.title = item.title;
    }
    self.viewController.navigationController.navigationBar.alpha = 1;//结束后显示原本导条
    kNavigationBarExist = NO;
    NSLog(@"WkWebView transition_end");
}

//WKNavigationDelegatePrivate 导航转场开始
- (void)_webViewDidBeginNavigationGesture:(WKWebView *)webView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.navigationDelegate performSelector:_cmd withObject:webView];
#pragma clang diagnostic pop
    kTransition_ing = YES;
    kNavigationBarExist = self.viewController.navigationController && !self.viewController.navigationController.navigationBarHidden;

    NSLog(@"WkWebView transition_begin");
}
#endif


@end
