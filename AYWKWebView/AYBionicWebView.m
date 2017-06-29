//
//  AYBionicWebView.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYBionicWebView.h"
#if AYWKWebView_bionicEnabled
#pragma mark -
#pragma mark - ------ bionicEnabled ==1
#pragma mark -
#import<CommonCrypto/CommonDigest.h>

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
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
@end

#pragma mark -
#pragma mark - AYBionicWebView


@interface AYBionicWebView ()
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) NSMutableDictionary <NSString*, NSArray<UINavigationItem*>*> *navigationItemsDict;
@property (nonatomic, assign) BOOL canUpdateNavigationItem;
@end


@implementation NSString (AYBionicWebView)

//+ (NSString *) uuidString {
//    uuid_t uuid;
//    uuid_generate(uuid);
//    char buffer[37] = {0};
//    uuid_unparse_upper(uuid, buffer);
//    return [NSString stringWithUTF8String:buffer];
//}

- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}
@end

@implementation UINavigationBar (AYBionicWebView)

-(void)setTitle:(NSString*)title {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_setTitle:) withObject:title afterDelay:0.4];
}

-(void)_setTitle:(NSString*)title {
    self.items.lastObject.title = title;
}
@end

@interface WKBackForwardListItem (AYBionicWebView)
@property (nonatomic, readonly) NSString *md5;
@end
@implementation WKBackForwardListItem (AYBionicWebView)

-(NSString *)md5 {
    NSString *md5 = aywkobjc_getAssociated(self, @selector(md5));
    if (md5.length == 0) {
        md5 = [self.URL.absoluteString md5];
        aywkobjc_setAssociated(self, @selector(md5), md5, YES);
    }
    return md5;
}

@end

static NSArray<UINavigationItem*> *kTransitionItem_t;
static NSArray<UINavigationItem*> *kTransitionItem_b;

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
        //              UIImage* image = [self imageWithUIView:panelView];//获取转场视图中的图片视图image（后一页）
                    }
                }else{
                    if (isFront) {
                        backForwardItem = webView.backForwardList.forwardItem;
        //              UIImage* image = [self imageWithUIView:panelView];//获取转场视图中的图片视图image（前一页）
                    }else{
                        backForwardItem = webView.backForwardList.currentItem;
                    }
                }
                
                
                UINavigationBar *originBar = webView.viewController.navigationController.navigationBar;
                UINavigationBar *customBar = [[UINavigationBar alloc] init];
                
//                UIImage *image = [self imageWithUIView:originBar];
//                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//                [customBar addSubview:imageView];
                
                NSString *key = backForwardItem.md5;
                NSArray<UINavigationItem*> *items = webView.navigationItemsDict[key];
                if (!items) {
                    items = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:originBar.items]] mutableCopy];
                    items.lastObject.title = backForwardItem.title;
                }
                if (isFront) {
                    kTransitionItem_t = items;
                }else {
                    kTransitionItem_b = items;
                }
                customBar.items = items;
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
        }else if ([view isKindOfClass:k_UIParallaxDimmingView_Class()]) {
            CGRect frame = view.frame;//底层阴影浮层视图
            frame.origin.y -= 64;
            frame.size.height += 64;
            view.frame = frame;//转场过程中的阴影浮层（丢改frame覆盖导航条区域）
        }
    }
}

-(UIImage*)imageWithUIView:(UIView*)view{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
//#endif

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
    self.canUpdateNavigationItem = YES;
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

-(NSMutableDictionary<NSString *,NSArray<UINavigationItem*> *> *)navigationItemsDict {
    if (!_navigationItemsDict) {
        _navigationItemsDict = [NSMutableDictionary dictionary];
    }
    return _navigationItemsDict;
}

-(void)webView:(WKWebView *)webView titleChange:(NSString *)title {
    if (self.canUpdateNavigationItem) {
        self.viewController.navigationController.navigationBar.title = title;
    }
    if ([self.observerDelegate respondsToSelector:_cmd]) {
        [self.observerDelegate webView:self titleChange:title];
    }
}



-(void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    if (kNavigationBarExist && (kTransition_ing || self.backNavigationGesture.state == UIGestureRecognizerStateBegan || self.forwardNavigationGesture.state == UIGestureRecognizerStateBegan)) {//可以使设置导航条跟随效果时候insertSubview了转场视图（导航条存在且正在显示，转场开始）
        view.tag = kTransitionTag;//为转场视图做标记
        aywkw_setAssociated(view, @"rootWKWebView", self, NO);//将self（WkWebView）给转场视图，后边获取导航栏需要
        self.viewController.navigationController.navigationBar.alpha = 0;//隐藏真实导航栏
    }
    [super insertSubview:view belowSubview:siblingSubview];
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    self.canUpdateNavigationItem = YES;
    [super webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

//WKNavigationDelegatePrivate 导航转场结束
- (void)_webViewDidEndNavigationGesture:(WKWebView *)webView withNavigationToBackForwardListItem:(WKBackForwardListItem *)item {//item 存在时候表示转场完成，item == nil 表示转场取消
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.navigationDelegate respondsToSelector:_cmd]) {
        [self.navigationDelegate performSelector:_cmd withObject:webView withObject:item];
    }
#pragma clang diagnostic pop
    kTransition_ing = NO;
    NSArray<UINavigationItem*> *nItem;
    if (item) {
        nItem = kTransitionItem_b;
    }else{
        nItem = kTransitionItem_t;
    }
    self.viewController.navigationController.navigationBar.alpha = 1;//结束后显示原本导条
    self.viewController.navigationController.navigationBar.items.lastObject.title = nItem.lastObject.title;
    kNavigationBarExist = NO;
    NSLog(@"WkWebView transition_end %@", nItem.lastObject.title);
}

//WKNavigationDelegatePrivate 导航转场开始
- (void)_webViewDidBeginNavigationGesture:(WKWebView *)webView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.navigationDelegate respondsToSelector:_cmd]) {
        [self.navigationDelegate performSelector:_cmd withObject:webView];
    }
#pragma clang diagnostic pop
    kTransition_ing = YES;
    kNavigationBarExist = self.viewController.navigationController && !self.viewController.navigationController.navigationBarHidden;
    self.canUpdateNavigationItem = NO;
    NSLog(@"WkWebView transition_begin %@",self.backForwardList.currentItem.title);
}

@end

#else
#pragma mark -
#pragma mark - ------ bionicEnabled == 0
#pragma mark -

@interface AYBionicWebView ()
@property (nonatomic, weak) UIViewController *viewController;
@end
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

-(void)webView:(WKWebView *)webView titleChange:(NSString *)title {
    self.viewController.navigationController.navigationBar.items.lastObject.title = title;
    if ([self.observerDelegate respondsToSelector:_cmd]) {
        [self.observerDelegate webView:self titleChange:title];
    }
}
@end

#endif






