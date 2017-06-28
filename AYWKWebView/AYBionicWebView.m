//
//  AYBionicWebView.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYBionicWebView.h"
#import <objc/runtime.h>

@interface AYWKWebView ()
@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *backNavigationGesture;
@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *forwardNavigationGesture;
@end
@interface AYBionicWebView ()
@property (nonatomic, weak) UIViewController *viewController;
//@property (nonatomic, strong) UIImageView *transitionImageView;

@end

CG_INLINE void aybw_setAssociated(id target, NSString *propertyName, id value , BOOL retain) {
    objc_setAssociatedObject(target, NSSelectorFromString(propertyName), value, retain?OBJC_ASSOCIATION_RETAIN_NONATOMIC:OBJC_ASSOCIATION_ASSIGN);
}

CG_INLINE id aybw_getAssociated(id target, NSString *propertyName) {
    return objc_getAssociatedObject(target, NSSelectorFromString(propertyName));
}

CG_INLINE void aybw_replaceMethod(Class _class, SEL _originSelector, SEL _newSelector) {
    Method oriMethod = class_getInstanceMethod(_class, _originSelector);
    Method newMethod = class_getInstanceMethod(_class, _newSelector);
    BOOL isAddedMethod = class_addMethod(_class, _originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod(_class, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}



@interface WKBackForwardListItem (transitionContext_ContainerView)
@property (nonatomic, strong) UINavigationBar *navigationBar;
-(void)navigationBarWithLeftItems:(NSArray<UIBarButtonItem*>*)leftItems rightItems:(NSArray<UIBarButtonItem*>*)rightItems;
@end
@implementation WKBackForwardListItem (transitionContext_ContainerView)
-(UINavigationBar *)navigationBar {
    return objc_getAssociatedObject(self, @selector(navigationBar));
}
-(void)setNavigationBar:(UINavigationBar *)navigationBar {
    objc_setAssociatedObject(self, @selector(navigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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


//static UINavigationBar *kNavigationBar;
static BOOL kTransition_ing = NO;

//@implementation NSObject (WKSwipeTransition)
//static BOOL kTransition_doCompletio = NO;
//+(void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Class class = NSClassFromString(@"_UIViewControllerOneToOneTransitionContext");
//        aybw_replaceMethod(class, NSSelectorFromString(@"_setCompletionHandler:"), NSSelectorFromString(@"f_setCompletionHandler:"));
//    });
//}
//-(void)f_setCompletionHandler:(void(^)(id context, BOOL didComplete))handler {
//    if (kTransition_ing) {
//        [self f_setCompletionHandler:^(id context, BOOL didComplete) {
//            if (!didComplete) {
//                kNavigationBar = nil;
//            }
//            NSLog(@"f_setCompletionHandler ");
////            kTransition_doCompletio = YES;
//            handler(context,didComplete);
////            kTransition_doCompletio = NO;
////            kTransition_ing = NO;
//        }];
//    }else {
//        [self f_setCompletionHandler:handler];
//    }
//}
//@end


static NSUInteger const kTransitionTag = 110192312;

@implementation UIView (transitionContext_ContainerView)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UIView class];
        aybw_replaceMethod(class, @selector(addSubview:), @selector(transition_addSubview:));
//        aybw_replaceMethod(class, @selector(removeFromSuperview), @selector(transition_removeFromSuperview));
        
    });
}

-(void)transition_addSubview:(UIView *)view {
    [self transition_addSubview:view];
    if (kTransition_ing) {
        if([self class] == [UIView class]) {
            [self addTransitionNavigationBarInViewIfNeeded:view];
        }
        if ([self isKindOfClass:NSClassFromString(@"_UIParallaxDimmingView")]) {
            if ([view class] == [UIView class]) {
                UIView *v = aybw_getAssociated(self, @"customBar");
                if (v) {
                    [self bringSubviewToFront:v];
                    aybw_setAssociated(self, @"customBar", nil, NO);
                }
            }
        }
    }
}

//-(void)transition_removeFromSuperview {
//    [self transition_removeFromSuperview];
//    if (self.tag == kTransitionTag && kTransition_ing) {
//        AYBionicWebView *webView = aybw_getAssociated(self, @"rootWKWebView");
//        aybw_setAssociated(self, @"rootWKWebView", nil, NO);
//        webView.viewController.navigationController.navigationBar.alpha = 1;
////        if (kNavigationBar) {
////            webView.viewController.title = kNavigationBar.items[0].title;
////            kNavigationBar = nil;
////        }
//        kTransition_ing = NO;
//        NSLog(@"WkWebView transition_end");
//    }
//    if (self.tag == 110) {
//        NSLog(@"");
//    }
//}

- (void)addTransitionNavigationBarInViewIfNeeded:(UIView*)view {
    if (self.tag == kTransitionTag) {
        if (view.subviews.count>0) {
            AYBionicWebView *webView = aybw_getAssociated(self, @"rootWKWebView");
            if (webView) {
                view.tag = 110;
                UIView *sView = view.subviews.firstObject;
                UIView *panelView = sView.clipsToBounds?view:sView;
                BOOL isGoBack = NO;//YES 后退; NO 前进
                if (webView.forwardNavigationGesture.state == UIGestureRecognizerStateBegan) {
                    isGoBack = NO;
                }
                if (webView.backNavigationGesture.state == UIGestureRecognizerStateBegan) {
                    isGoBack = YES;
                }
                
                BOOL isFront;//YES 上层; NO 底层
                
                if ([sView isKindOfClass:NSClassFromString(@"_UIParallaxDimmingView")] && [sView.subviews.firstObject isKindOfClass:[UIImageView class]]) {
                    UIImageView *imageView = sView.subviews.firstObject;
                    CGRect frame = imageView.frame;
                    frame.origin.y -= 64;
                    frame.size.height += 64;
                    imageView.frame = frame;
                    isFront = YES;
                }else{
                    isFront = NO;
                }
                
                WKBackForwardListItem *backForwardItem;
//                BOOL netSet_kNavigationBar = NO;
                if (isGoBack) {
                    if (isFront) {
                        backForwardItem = webView.backForwardList.currentItem;
                    }else{
                        backForwardItem = webView.backForwardList.backItem;
//                        netSet_kNavigationBar = YES;
                    }
                }else{
                    if (isFront) {
                        backForwardItem = webView.backForwardList.forwardItem;
//                        netSet_kNavigationBar = YES;
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
                
//                if (netSet_kNavigationBar) {
////                  kNavigationBar = customBar;
//                    UIImage* image = [self imageWithUIView:panelView];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"transitionImageNotification" object:image];
//                }
                
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
                
                aybw_setAssociated(panelView, @"customBar", customBar, NO);
                
                [panelView addSubview:customBar];
                
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



@implementation AYBionicWebView

-(instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self customIntitialization];
    }
    return self;
}
-(void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"transitionImageNotification" object:nil];
}
- (void)customIntitialization {
    super.allowsLinkPreview = NO;
    super.allowsForwardNavigationGestures = NO;
    super.allowSelectionGestures = NO;
    super.allowLongPressGestures = NO;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transitionImageNotification:) name:@"transitionImageNotification" object:nil];

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

-(void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    if (kTransition_ing || self.backNavigationGesture.state == UIGestureRecognizerStateBegan || self.forwardNavigationGesture.state == UIGestureRecognizerStateBegan) {
        view.tag = kTransitionTag;
        aybw_setAssociated(view, @"rootWKWebView", self, NO);
        self.viewController.navigationController.navigationBar.alpha = 0;
    }
    [super insertSubview:view belowSubview:siblingSubview];
}


//-(UIImageView *)transitionImageView {
//    if (!_transitionImageView) {
//        _transitionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 65)];
//        [self addSubview:_transitionImageView];
//        //        _transitionImageView.alpha = 0.5;
//    }
//    return _transitionImageView;
//}

//-(void)transitionImageNotification:(NSNotification *)notification {
//    self.transitionImageView.image = notification.object;
//}

- (void)_webViewDidEndNavigationGesture:(WKWebView *)webView withNavigationToBackForwardListItem:(WKBackForwardListItem *)item {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.navigationDelegate performSelector:_cmd withObject:webView withObject:item];
#pragma clang diagnostic pop
    kTransition_ing = NO;
    if (item) {
        self.viewController.title = item.title;
    }
    self.viewController.navigationController.navigationBar.alpha = 1;
    NSLog(@"WkWebView transition_end");
}

- (void)_webViewDidBeginNavigationGesture:(WKWebView *)webView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.navigationDelegate performSelector:_cmd withObject:webView];
#pragma clang diagnostic pop
    kTransition_ing = YES;
    NSLog(@"WkWebView transition_begin");
}


@end
