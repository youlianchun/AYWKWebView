//
//  AYWKWebView.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/5/27.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYWKWebView.h"
#import "DelegateInterceptor.h"
#import "aywkw_objc.h"

#pragma mark -
#pragma mark - WKContentView
@implementation UIView (WKContentView)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = objc_getClass("WKContentView");
        
        BOOL addIsSecureTextEntry = aywk_addMethod(cls, sel_registerName("isSecureTextEntry"), "B@:", ^BOOL(id self){
            return NO;
        });
        BOOL addSecureTextEntry = aywk_addMethod(cls, sel_registerName("secureTextEntry"), "B@:", ^BOOL(id self){
            return NO;
        });
        
        if (!addIsSecureTextEntry || !addSecureTextEntry) {
            NSLog(@"secureTextEntry-Crash->修复失败");
        }
    });
}
@end

#pragma mark -
#pragma mark - WkObserver
static NSString * const kWebViewEstimatedProgress = @"estimatedProgress";
static NSString * const kWebViewCanGoBack = @"canGoBack";
static NSString * const kWebViewCanGoForward = @"canGoForward";
static NSString * const kWebViewTitle = @"title";
static NSString * const kWebViewUrl = @"URL";//请求的url
static NSString * const kWebViewLoading = @"loading";//当前是否正在加载网页
static NSString * const kWebViewCertificateChain = @"certificateChain";//当前导航的证书链
static NSString * const kWebViewHasOnlySecureContent = @"hasOnlySecureContent";//标识页面中的所有资源是否通过安全加密连接来加载

@interface AYWKWebView ()
-(DelegateInterceptor<id<AYWKObserverDelegate>> *)obsDelegateInterceptor;
@end

@interface WkObserver : NSObject
@end
@implementation WkObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    id newValue = [change objectForKey:@"new"];
    AYWKWebView *webView = object;
    if (keyPath == kWebViewEstimatedProgress && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:estimatedProgress:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView estimatedProgress:[newValue doubleValue]];
        return;
    }
    if (keyPath == kWebViewCanGoBack && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:canGoBackChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView canGoBackChange:[newValue boolValue]];
        return;
    }
    if (keyPath == kWebViewCanGoForward && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:canGoForwardChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView canGoForwardChange:[newValue boolValue]];
        return;
    }
    if (keyPath == kWebViewTitle && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:titleChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView titleChange:newValue];
        return;
    }
    if (keyPath == kWebViewUrl && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:urlChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView urlChange:newValue];
        return;
    }
    if (keyPath == kWebViewLoading && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:loadingChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView loadingChange:[newValue boolValue]];
        return;
    }
    if (keyPath == kWebViewCertificateChain && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:certificateChainChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView certificateChainChange:newValue];
        return;
    }
    if (keyPath == kWebViewHasOnlySecureContent && [webView.obsDelegateInterceptor respondsToSelector:@selector(webView:hasOnlySecureContentChange:)]) {
        [webView.obsDelegateInterceptor.mySelf webView:webView hasOnlySecureContentChange:[newValue boolValue]];
        return;
    }
}

@end

#pragma mark -
#pragma mark - AYWKWebView
@interface AYWKWebView ()
@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *backNavigationGesture;
@property (nonatomic, weak) UIScreenEdgePanGestureRecognizer *forwardNavigationGesture;

@property (nonatomic, weak) UILongPressGestureRecognizer *selectionGesture;
@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong) WkObserver *wkObserver;
@property (nonatomic, assign) BOOL wkObserverEnabled;

@property (nonatomic, strong) DelegateInterceptor<id<WKNavigationDelegate>> * navDelegateInterceptor;
@property (nonatomic, strong) DelegateInterceptor<id<WKUIDelegate>> * uiDelegateInterceptor;
@property (nonatomic, strong) DelegateInterceptor<id<AYWKObserverDelegate>> * obsDelegateInterceptor;
@end

@implementation AYWKWebView
@synthesize observerDelegate = _observerDelegate;
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
    BOOL hasPrefix_var = [str hasPrefix:@"/"];
    BOOL hasPrefix_file = [str hasPrefix:@"file://"];
    if (hasPrefix_var || hasPrefix_file)
    {
        NSURL *_url = request.URL;
        if (hasPrefix_var) {
            _url = [NSURL fileURLWithPath:url];
        }
        if (aywkw_systemVersion() >= 9.0) {
            return [self loadFileURL:_url allowingReadAccessToURL:_url];
        }else{
            NSURLRequest *_request = request;
            if (_url != _request.URL) {
                _request = [NSURLRequest requestWithURL:_url];
            }
            return [super loadRequest:_request];
        }
    }
    else if ([[request.HTTPMethod uppercaseString] isEqualToString:@"POST"])
    {
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
    }
    else
    {
        return [super loadRequest:request];
    }
}


-(instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self _customIntitialization];
    }
    return self;
}

- (void)_customIntitialization{
    self.navigationDelegate = nil;
    self.UIDelegate = nil;
    self.observerDelegate = nil;
    self.wkObserver = [[WkObserver alloc] init];
    self.wkObserverEnabled = YES;
    
    self.allowsBackNavigationGestures = YES;
    self.allowsForwardNavigationGestures = YES;
    [super setAllowsBackForwardNavigationGestures:YES];//执行后会添加手势
}

-(void)dealloc {
    self.wkObserverEnabled = NO;
    _wkObserver = nil;
    _navDelegateInterceptor = nil;
    _uiDelegateInterceptor = nil;
    _obsDelegateInterceptor = nil;
}

bool aywkw_isBackForwardNavigationGestures(UIGestureRecognizer*gestureRecognizer) {
    return [gestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]] && [gestureRecognizer.description containsString:@"handleNavigationTransition:"];
}

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (aywkw_isBackForwardNavigationGestures(gestureRecognizer)) {
        UIScreenEdgePanGestureRecognizer *navigationGestures = (UIScreenEdgePanGestureRecognizer*)gestureRecognizer;
        if (navigationGestures.edges == UIRectEdgeLeft) {
            self.backNavigationGesture = navigationGestures;
        }
        if (navigationGestures.edges == UIRectEdgeRight) {
            self.forwardNavigationGesture = navigationGestures;
        }
    }
    [super addGestureRecognizer:gestureRecognizer];
}

-(void)setWkObserverEnabled:(BOOL)wkObserverEnabled {
    if (_wkObserverEnabled == wkObserverEnabled) {
        return;
    }
    _wkObserverEnabled = wkObserverEnabled;
    [self wkObserverSet:_wkObserverEnabled];
}

-(void)wkObserverSet:(BOOL)enabled {
    static NSArray* kObserverKeyPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kObserverKeyPath = @[kWebViewEstimatedProgress, kWebViewCanGoBack, kWebViewCanGoForward, kWebViewTitle, kWebViewUrl, kWebViewLoading, kWebViewCertificateChain, kWebViewHasOnlySecureContent];
    });
    
    for (NSString *keyPath in kObserverKeyPath) {
        if (enabled) {
            [self addObserver:self.wkObserver forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
        }else {
            [self removeObserver:self.wkObserver forKeyPath:keyPath];
        }
    }
}

-(void)setObserverDelegate:(id<AYWKObserverDelegate>)observerDelegate {
    self.obsDelegateInterceptor = [[DelegateInterceptor alloc] initWithOriginal:observerDelegate accepter:self];
    _observerDelegate = self.obsDelegateInterceptor.mySelf;
}

-(id<AYWKObserverDelegate>)observerDelegate {
    return self.obsDelegateInterceptor.original;
}

double aywkw_systemVersion() {
    return [[[UIDevice currentDevice] systemVersion] doubleValue];
}

#pragma mark - allowsLinkPreview
-(BOOL)allowsLinkPreview {
    if (aywkw_systemVersion() >= 9.0) {
        return [super allowsLinkPreview];
    }
    return NO;
}

-(void)setAllowsLinkPreview:(BOOL)allowsLinkPreview {
    if (aywkw_systemVersion() >= 9.0) {
        [super setAllowsLinkPreview:allowsLinkPreview];
    }
}

#pragma mark - Gestures
#pragma mark backNavigationGesture
-(void)setAllowsBackNavigationGestures:(BOOL)allowsBackNavigationGestures {
    _allowsBackNavigationGestures = allowsBackNavigationGestures;
    self.backNavigationGesture.enabled = _allowsBackNavigationGestures;
}
-(void)setBackNavigationGesture:(UIScreenEdgePanGestureRecognizer *)backNavigationGesture {
    _backNavigationGesture = backNavigationGesture;
    _backNavigationGesture.enabled = self.allowsBackNavigationGestures;
}

#pragma mark forwardNavigationGesture
-(void)setAllowsForwardNavigationGestures:(BOOL)allowsForwardNavigationGestures {
    _allowsForwardNavigationGestures = allowsForwardNavigationGestures;
    self.forwardNavigationGesture.enabled = _allowsForwardNavigationGestures;
}
-(void)setForwardNavigationGesture:(UIScreenEdgePanGestureRecognizer *)forwardNavigationGesture {
    _forwardNavigationGesture = forwardNavigationGesture;
    _forwardNavigationGesture.enabled = self.allowsForwardNavigationGestures;
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
    self.navDelegateInterceptor = [[DelegateInterceptor alloc] initWithOriginal:navigationDelegate accepter:self];
    [super setNavigationDelegate:self.navDelegateInterceptor.mySelf];
}

-(void)setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    self.uiDelegateInterceptor = [[DelegateInterceptor alloc] initWithOriginal:UIDelegate accepter:self];
    [super setUIDelegate:self.uiDelegateInterceptor.mySelf];
}

-(id<WKNavigationDelegate>)navigationDelegate {
    return self.navDelegateInterceptor.original;
}

-(id<WKUIDelegate>)UIDelegate {
    return self.uiDelegateInterceptor.original;
}

#pragma mark -
#pragma mark UrlSchemes
NSArray* aywkw_infoUrlSchemes() {
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

NSArray* aywkw_infoOpenURLs() {
    static NSMutableArray *kInfoOpenURLs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kInfoOpenURLs = [NSMutableArray array];
        [kInfoOpenURLs addObject:@"tel"];
        [kInfoOpenURLs addObject:@"telprompt"];
        [kInfoOpenURLs addObject:@"sms"];
        [kInfoOpenURLs addObject:@"mailto"];
        [kInfoOpenURLs addObject:@"itms-apps"];
        [kInfoOpenURLs addObject:@"itms"];
    });
    return kInfoOpenURLs;
}

bool aywkw_isOpenUrl(NSURL *url) {
   return [aywkw_infoOpenURLs() containsObject:url.scheme] ||
    [url.absoluteString isEqualToString:UIApplicationOpenSettingsURLString] ||
    [aywkw_infoUrlSchemes() containsObject:url.scheme];
}

void aywkw_openUrl(NSURL *url, void(^befor)()) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:url]){
            if (befor) {
                befor();
            }
            [app openURL:url];
        }
    });
}
#pragma mark OpenURLs拦截
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (aywkw_isOpenUrl(url)) {
        decisionHandler(WKNavigationActionPolicyCancel);
        aywkw_openUrl(url, ^{
            aywkw_userInteractionSleep(self, 0.2);
        });
        return;
    }
    
    if ([self.navDelegateInterceptor originalRespondsToSelector:_cmd]) {
        [self.navDelegateInterceptor.original webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark  https
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([self.navDelegateInterceptor originalRespondsToSelector:_cmd]) {
        [self.navDelegateInterceptor.original webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
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
    if ([self.navDelegateInterceptor originalRespondsToSelector:_cmd]) {
        [self.navDelegateInterceptor.original webViewWebContentProcessDidTerminate:webView];
    }else{
        //    当 WKWebView 总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload](这个时候 webView.URL 取值尚不为 nil）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面，H5侧也要做相应的适配操作。
        [webView reload];
    }
}


#pragma mark -

#pragma mark - 响应间隔禁止
void aywkw_userInteractionSleep(UIView *view, double interval) {
    if(interval <= 0 || !view.userInteractionEnabled) {
        return;
    }
    view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        view.userInteractionEnabled = YES;
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
    if (aywkw_systemVersion() >= 9.0) {
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

