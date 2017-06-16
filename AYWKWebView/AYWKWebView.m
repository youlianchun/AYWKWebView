//
//  AYWKWebView.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/5/27.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYWKWebView.h"
#import <objc/runtime.h>

//void set_Associated(id target, NSString *propertyName, id value) {
//    objc_setAssociatedObject(target, NSSelectorFromString(propertyName), value, OBJC_ASSOCIATION_ASSIGN);
//}
//id get_Associated(id target, NSString *propertyName) {
//    return objc_getAssociatedObject(target, NSSelectorFromString(propertyName));
//}

static NSString*  kWebViewEstimatedProgress = @"estimatedProgress";
static NSString*  kWebViewCanGoBack = @"canGoBack";
static NSString*  kWebViewCanGoForward = @"canGoForward";
static NSString*  kWebViewTitle = @"title";

static NSString*  kWebViewUrl = @"url";//请求的url
static NSString*  kWebViewLoading = @"loading";//当前是否正在加载网页
static NSString*  kWebViewCertificateChain = @"certificateChain";//当前导航的证书链
static NSString*  kWebViewHasOnlySecureContent = @"hasOnlySecureContent";//标识页面中的所有资源是否通过安全加密连接来加载

@interface WkObserver : NSObject
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, weak) AYWKWebView *webView;
@end
@implementation WkObserver
-(void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    if (_enabled) {
        [self addObserver:self forKeyPath:kWebViewEstimatedProgress options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewCanGoBack options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewCanGoForward options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewTitle options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewUrl options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewLoading options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewCertificateChain options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kWebViewHasOnlySecureContent options:NSKeyValueObservingOptionNew context:nil];
        
    }else{
        [self removeObserver:self forKeyPath:kWebViewEstimatedProgress];
        [self removeObserver:self forKeyPath:kWebViewCanGoBack];
        [self removeObserver:self forKeyPath:kWebViewCanGoForward];
        [self removeObserver:self forKeyPath:kWebViewTitle];
        [self removeObserver:self forKeyPath:kWebViewUrl];
        [self removeObserver:self forKeyPath:kWebViewLoading];
        [self removeObserver:self forKeyPath:kWebViewCertificateChain];
        [self removeObserver:self forKeyPath:kWebViewHasOnlySecureContent];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    id newValue = [change objectForKey:@"new"];
    if ([keyPath isEqualToString:kWebViewEstimatedProgress] && [self.webView.observerDelegate respondsToSelector:@selector(webView:estimatedProgress:)]) {
        [self.webView.observerDelegate webView:self.webView estimatedProgress:[newValue doubleValue]];
        return;
    }
    if ([keyPath isEqualToString:kWebViewCanGoBack] && [self.webView.observerDelegate respondsToSelector:@selector(webView:canGoBackChange:)]) {
        [self.webView.observerDelegate webView:self.webView canGoBackChange:[newValue boolValue]];
        return;
    }
    if ([keyPath isEqualToString:kWebViewCanGoForward] && [self.webView.observerDelegate respondsToSelector:@selector(webView:canGoForwardChange:)]) {
        [self.webView.observerDelegate webView:self.webView canGoForwardChange:[newValue boolValue]];
        return;
    }
    if ([keyPath isEqualToString:kWebViewTitle] && [self.webView.observerDelegate respondsToSelector:@selector(webView:titleChange:)]) {
        [self.webView.observerDelegate webView:self.webView titleChange:newValue];
        return;
    }
    if ([keyPath isEqualToString:kWebViewUrl] && [self.webView.observerDelegate respondsToSelector:@selector(webView:urlChange:)]) {
        [self.webView.observerDelegate webView:self.webView urlChange:newValue];
        return;
    }
    if ([keyPath isEqualToString:kWebViewLoading] && [self.webView.observerDelegate respondsToSelector:@selector(webView:loadingChange:)]) {
        [self.webView.observerDelegate webView:self.webView loadingChange:[newValue boolValue]];
        return;
    }
    if ([keyPath isEqualToString:kWebViewCertificateChain] && [self.webView.observerDelegate respondsToSelector:@selector(webView:certificateChainChange:)]) {
        [self.webView.observerDelegate webView:self.webView certificateChainChange:newValue];
        return;
    }
    if ([keyPath isEqualToString:kWebViewHasOnlySecureContent] && [self.webView.observerDelegate respondsToSelector:@selector(webView:hasOnlySecureContentChange:)]) {
        [self.webView.observerDelegate webView:self.webView hasOnlySecureContentChange:[newValue boolValue]];
        return;
    }
}
@end


@interface AYWKWebView ()

@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *backNavigationGesture;
@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *forwardNavigationGesture;
@property (nonatomic, assign) BOOL allowsBackNavigationGesturesSet;

@property (nonatomic, weak) UILongPressGestureRecognizer *selectionGesture;
@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong) WkObserver *wkObserver;
@property (nonatomic, weak) id navigationDelegateReceiver;
@property (nonatomic, weak) id UIDelegateReceiver;

@end


@implementation UIView (WKContentView)

static NSString *kLongPressRecognizedFlag = @"_longPressRecognized:";
Class k_UITextSelectionForceGesture_Class (){
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cls = NSClassFromString(@"_UITextSelectionForceGesture");
    });
    return cls;
}


+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = NSClassFromString(@"WKContentView");
        SEL originalSelector = @selector(addGestureRecognizer:);
        SEL swizzledSelector = @selector(wkContentView_addGestureRecognizer:);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        SEL isSecureTextEntry = NSSelectorFromString(@"isSecureTextEntry");
        SEL secureTextEntry = NSSelectorFromString(@"secureTextEntry");
        BOOL addIsSecureTextEntry = class_addMethod(class, isSecureTextEntry, (IMP)secureTextEntryIMP, "B@:");
        BOOL addSecureTextEntry = class_addMethod(class, secureTextEntry, (IMP)secureTextEntryIMP, "B@:");
        if (!addIsSecureTextEntry || !addSecureTextEntry) {
            NSLog(@"WKContentView-Crash->修复失败");
        }
    });
}

BOOL secureTextEntryIMP(id sender, SEL cmd) {
    return NO;
}

-(void)wkContentView_addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    id obj = self.superview.superview;
    if ([obj isKindOfClass:[AYWKWebView class]]) {
        AYWKWebView *webView = obj;
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] ) {
            if ([gestureRecognizer isKindOfClass:k_UITextSelectionForceGesture_Class()] ) {
                webView.selectionGesture = (UILongPressGestureRecognizer*)gestureRecognizer;
            }else if ([gestureRecognizer.description containsString:kLongPressRecognizedFlag]) {
                webView.longPressGesture = (UILongPressGestureRecognizer*)gestureRecognizer;
            }
        }
    }
    [self wkContentView_addGestureRecognizer:gestureRecognizer];
}

@end

NSArray* infoUrlSchemes() {
    static NSMutableArray *kInfoUrlSchemes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kInfoUrlSchemes = [NSMutableArray array];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSMutableDictionary *dict  = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        NSArray *urlTypes = dict[@"CFBundleURLTypes"];
        for (NSDictionary *urlType in urlTypes) {
            [kInfoUrlSchemes addObjectsFromArray:urlType[@"CFBundleURLSchemes"]];
        }
    });
    return kInfoUrlSchemes;
}

NSArray* infoOpenURLs() {
    static NSMutableArray *kInfoOpenURLs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kInfoOpenURLs = [NSMutableArray array];
        [kInfoOpenURLs addObject:@"tel"];
        [kInfoOpenURLs addObject:@"telprompt"];
        [kInfoOpenURLs addObject:@"sms"];
        [kInfoOpenURLs addObject:@"mailto"];
    });
    return kInfoOpenURLs;
}


@implementation AYWKWebView

#pragma mark - evaluateJavaScript fix

-(void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    id strongSelf = self;
    [super evaluateJavaScript:javaScriptString completionHandler:^(id object, NSError *error) {
        [strongSelf title];
        if (completionHandler) {
            completionHandler(object, error);
        }
    }];
}
#pragma mark - post
-(WKNavigation *)loadRequest:(NSURLRequest *)request {
    NSString *url = request.URL.absoluteString;
    NSString *str = [url lowercaseString];
    BOOL loactionUrl = [str hasPrefix:@"/"] || [str hasPrefix:@"file://"];
    if (loactionUrl) {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
            return [self loadFileURL:request.URL allowingReadAccessToURL:request.URL];
        }else{
            return [super loadRequest:request];
        }
    } else
        if ([[request.HTTPMethod uppercaseString] isEqualToString:@"POST"]){
            NSString *params = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
            if ([params containsString:@"="]) {
                params = [params stringByReplacingOccurrencesOfString:@"=" withString:@"\":\""];
                params = [params stringByReplacingOccurrencesOfString:@"&" withString:@"\",\""];
                params = [NSString stringWithFormat:@"{\"%@\"}", params];
            }else{
                params = @"{}";
            }
            NSString *postJavaScript = [NSString stringWithFormat:@"\
                                        var url = '%@';\
                                        var params = %@;\
                                        var form = document.createElement('form');\
                                        form.setAttribute('method', 'post');\
                                        form.setAttribute('action', url);\
                                        for(var key in params) {\
                                        if(params.hasOwnProperty(key)) {\
                                        var hiddenField = document.createElement('input');\
                                        hiddenField.setAttribute('type', 'hidden');\
                                        hiddenField.setAttribute('name', key);\
                                        hiddenField.setAttribute('value', params[key]);\
                                        form.appendChild(hiddenField);\
                                        }\
                                        }\
                                        document.body.appendChild(form);\
                                        form.submit();", url, params];
            __weak typeof(self) wself = self;
            [self evaluateJavaScript:postJavaScript completionHandler:^(id object, NSError * _Nullable error) {
                if (error && [wself.navigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [wself.navigationDelegate webView:wself didFailProvisionalNavigation:nil withError:error];
                    });
                }
            }];
            return nil;
        }else{
            return [super loadRequest:request];
        }
}


-(instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self customIntitialization];
    }
    return self;
}

- (void)customIntitialization{
    self.navigationDelegate = nil;
    self.UIDelegate = nil;
    self.wkObserver = [[WkObserver alloc] init];
    self.wkObserver.webView = self;
    [self _allowsBackForwardNavigationGestures];
    [self _allowLongPressGestures];
}

-(void)dealloc {
    self.wkObserver.enabled = NO;
    self.wkObserver = nil;
    self.backNavigationGesture = nil;
    self.forwardNavigationGesture = nil;
}

-(void)_allowLongPressGestures {
    self.allowSelectionGestures = YES;
    self.allowLongPressGestures = YES;
    UIView *wkContentView = self.scrollView.subviews.firstObject;
    NSArray *gestureRecognizers = wkContentView.gestureRecognizers;
    for (long i = gestureRecognizers.count-1, n = 0; i>0 && n <= 2; i--) {
        UIGestureRecognizer *gestureRecognizer = gestureRecognizers[i];
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] ) {
            if ([gestureRecognizer isKindOfClass:k_UITextSelectionForceGesture_Class()] ) {
                self.selectionGesture = (UILongPressGestureRecognizer*)gestureRecognizer;
                n++;
            }else if ([gestureRecognizer.description containsString:kLongPressRecognizedFlag]) {
                self.longPressGesture = (UILongPressGestureRecognizer*)gestureRecognizer;
                n++;
            }
        }
    }
}

-(void)_allowsBackForwardNavigationGestures {
    self.allowsBackNavigationGesturesSet = YES;
    [super setAllowsBackForwardNavigationGestures:YES];
    self.allowsBackNavigationGesturesSet = NO;
}

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (self.allowsBackNavigationGesturesSet && [gestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
        UIScreenEdgePanGestureRecognizer *navigationGestures = (UIScreenEdgePanGestureRecognizer*)gestureRecognizer;
        if (navigationGestures.edges == UIRectEdgeLeft) {
            navigationGestures.enabled = self.backNavigationGesture.enabled;
            self.backNavigationGesture = navigationGestures;
        }
        if (navigationGestures.edges == UIRectEdgeRight) {
            navigationGestures.enabled = self.forwardNavigationGesture.enabled;
            self.forwardNavigationGesture = navigationGestures;
        }
    }
    [super addGestureRecognizer:gestureRecognizer];
}


-(BOOL)allowsLinkPreview {
    if (([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)) {
        return [super allowsLinkPreview];
    }
    return NO;
}

-(void)setAllowsLinkPreview:(BOOL)allowsLinkPreview {
    if (([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)) {
        [super setAllowsLinkPreview:allowsLinkPreview];
    }
}

-(BOOL)allowsBackNavigationGestures {
    return  self.backNavigationGesture.enabled;
}

-(void)setAllowsBackNavigationGestures:(BOOL)allowsBackNavigationGestures {
    if (self.allowsBackNavigationGestures != allowsBackNavigationGestures) {
        self.backNavigationGesture.enabled = allowsBackNavigationGestures;
    }
}

-(BOOL)allowsForwardNavigationGestures {
    return self.forwardNavigationGesture.enabled;
}

-(void)setAllowsForwardNavigationGestures:(BOOL)allowsForwardNavigationGestures {
    if (self.allowsForwardNavigationGestures != allowsForwardNavigationGestures) {
        self.forwardNavigationGesture.enabled = allowsForwardNavigationGestures;
    }
}

-(void)setSelectionGesture:(UILongPressGestureRecognizer *)selectionGesture {
    _selectionGesture = selectionGesture;
    _selectionGesture.enabled = self.allowSelectionGestures;
}

-(void)setLongPressGesture:(UILongPressGestureRecognizer *)longPressGesture {
    _longPressGesture = longPressGesture;
    _selectionGesture.enabled = self.allowLongPressGestures;
}

-(void)setAllowSelectionGestures:(BOOL)allowSelectionGestures {
    _allowSelectionGestures = allowSelectionGestures;
    self.selectionGesture.enabled = _allowSelectionGestures;
}

-(void)setAllowLongPressGestures:(BOOL)allowLongPressGestures {
    _allowLongPressGestures = allowLongPressGestures;
    self.longPressGesture.enabled = _allowLongPressGestures;
}

-(void)setObserverDelegate:(id<AYWKObserverDelegate>)observerDelegate {
    _observerDelegate = observerDelegate;
    self.wkObserver.enabled = observerDelegate != nil;
}



#pragma mark - 滚动速率
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height>scrollView.bounds.size.height*1.5) {//html页面高度小于1.5倍webView高度时候不做速率处理
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }
}
#pragma mark - js调用

-(id)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString {
    __block NSString* result = nil;
    if (javaScriptString.length>0) {
        __block BOOL isExecuted = NO;
        [self evaluateJavaScript:javaScriptString completionHandler:^(id obj, NSError *error) {
            result = obj;
            isExecuted = YES;
        }];
        
        while (isExecuted == NO) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    return result;
}

#pragma mark - 代理拦截

-(void)setNavigationDelegate:(id<WKNavigationDelegate>)navigationDelegate {
    id<WKNavigationDelegate> delegate = (id<WKNavigationDelegate>)self;
    if (delegate != navigationDelegate) {
        self.navigationDelegateReceiver = navigationDelegate;
    }
    [super setNavigationDelegate:delegate];
}

-(void)setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    id<WKUIDelegate> delegate = (id<WKUIDelegate>)self;
    if (delegate != UIDelegate) {
        self.UIDelegateReceiver = UIDelegate;
    }
    [super setUIDelegate:delegate];
}

-(id<WKNavigationDelegate>)navigationDelegate {
    return self.navigationDelegateReceiver;
}

-(id<WKUIDelegate>)UIDelegate {
    return self.UIDelegateReceiver;
}



#pragma mark --
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    UIApplication *app = [UIApplication sharedApplication];
    if([infoOpenURLs() containsObject:url.scheme]) {
        if ([app canOpenURL:url]){
            [self userInteractionDisableWithTime:0.2];
            [app openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    if([infoUrlSchemes() containsObject:url.scheme] ||
       [url.absoluteString containsString:@"itunes.apple.com"] ||
       [url.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        if ([app canOpenURL:url]){
            [app openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    if ([self.navigationDelegateReceiver respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.navigationDelegateReceiver webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }else{
        decisionHandler(YES);
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([self.navigationDelegateReceiver respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [self.navigationDelegateReceiver webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }else{
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([challenge previousFailureCount] == 0) {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    if ([self.navigationDelegateReceiver respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [self.navigationDelegateReceiver webViewWebContentProcessDidTerminate:webView];
    }else{
        //    当 WKWebView 总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload](这个时候 webView.URL 取值尚不为 nil）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面，H5侧也要做相应的适配操作。
        [webView reload];
    }
}

#pragma mark - 代理转发
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return self;
    }
    if (self.navigationDelegateReceiver && [self.navigationDelegateReceiver respondsToSelector:aSelector]) {
        return self.navigationDelegateReceiver;
    }
    if (self.UIDelegateReceiver && [self.UIDelegateReceiver respondsToSelector:aSelector]) {
        return self.UIDelegateReceiver;
    }
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
//    NSString*selName=NSStringFromSelector(aSelector);
//    if ([selName hasPrefix:@"keyboardInput"] || [selName isEqualToString:@"customOverlayContainer"]) {//键盘输入代理过滤
//        return NO;
//    }
    if (self.navigationDelegateReceiver && [self.navigationDelegateReceiver respondsToSelector:aSelector]) {
        return YES;
    }
    if (self.UIDelegateReceiver && [self.UIDelegateReceiver respondsToSelector:aSelector]) {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}


#pragma mark -

#pragma mark - 响应间隔禁止
-(void)userInteractionDisableWithTime:(double)interval {
    if(time <= 0 && !self.userInteractionEnabled) {
        return;
    }
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
}

#pragma mark - 截图
-(UIImage*)screenshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    for (UIView *subView in self.subviews) {
        [subView drawViewHierarchyInRect:subView.bounds afterScreenUpdates:YES];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark - class
#pragma mark - 缓存清理
+ (void)clearCache {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        //        NSSet *websiteDataTypes = [NSSet setWithArray:@[
        ////                                                        磁盘缓存
        //                                                        WKWebsiteDataTypeDiskCache,
        //
        ////                                                        离线APP缓存
        //                                                        //WKWebsiteDataTypeOfflineWebApplicationCache,
        //
        ////                                                        内存缓存
        //                                                        WKWebsiteDataTypeMemoryCache,
        //
        ////                                                        web LocalStorage 缓存
        //                                                        //WKWebsiteDataTypeLocalStorage,
        //
        ////                                                        web Cookies缓存
        //                                                        //WKWebsiteDataTypeCookies,
        //
        ////                                                        SessionStorage 缓存
        //                                                        //WKWebsiteDataTypeSessionStorage,
        //
        ////                                                        索引DB缓存
        //                                                        //WKWebsiteDataTypeIndexedDBDatabases,
        //
        ////                                                        数据库缓存
        //                                                        //WKWebsiteDataTypeWebSQLDatabases
        //
        //                                                        ]];
        //// All kinds of data
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        //// Date from
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        //// Execute
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            // Done
        }];
    } else {
        
        NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        
        NSString *cookiesFolderPath = [NSString stringWithFormat:@"%@/Cookies",libraryDir];
        NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
        NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:&error];
    }
}

@end