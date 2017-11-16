////
////  AYWKWebView+Cookie.m
////  AYWKWebView
////
////  Created by YLCHUN on 2017/11/15.
////  Copyright © 2017年 ylchun. All rights reserved.
////
//
//#import "AYWKWebView+Cookie.h"
//#import "aywkw_objc.h"
//
//#pragma mark - cookie shareProcessPool
//
//@implementation  WKWebViewConfiguration (ShareProcessPool)
//
////共享进程池
//WKProcessPool *shareProcessPool() {
//    static WKProcessPool *kProcessPool;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kProcessPool = [[WKProcessPool alloc] init];
//    });
//    return kProcessPool;
//}
//
//-(WKProcessPool *)processPool {
//    WKProcessPool *processPool = aywkw_getAssociated(self, @"_shareProcessPool");
//    if (!processPool) {
//        processPool = shareProcessPool();
//        [self setProcessPool:processPool];
//    }
//    return processPool;
//}
//
//- (void)setProcessPool:(WKProcessPool *)processPool {
//    aywkw_setAssociated(self, @"_shareProcessPool", processPool, NO);
//}
//
//@end
//
//
//@interface AYWKWebView ()
//@property (nonatomic, assign) WKWebView* webViewCookie;
//@end
//@implementation  AYWKWebView (Cookie)
//
//
//-(WKWebView *)webViewCookie {
//    WKWebView *webView = aywkobjc_getAssociated(self, @selector(webViewCookie));
//    if (!webView) {
//        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
//        configuration.processPool = self.configuration.processPool;
//        webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
//        [self setWebViewCookie:webView];
//    }
//    return webView;
//}
//
//-(void)setWebViewCookie:(WKWebView *)webViewCookie {
//    aywkobjc_setAssociated(self, @selector(webViewCookie), webViewCookie, YES);
//}
//
// WKWebView *aywk_webView_processPool() {
//    static WKWebView* kWebView;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
//        configuration.processPool = shareProcessPool();
//        kWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
//    });
//    return kWebView;
//}
//
// NSMutableDictionary* aywk_cookieDict() {
//    static NSMutableDictionary *kDict;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kDict = [NSMutableDictionary dictionary];
//    });
//    return kDict;
//}
//
//void aywk_setCookies(NSDictionary *cookies) {
//    WKWebView *webView = aywk_webView_processPool();
//    NSMutableURLRequest *request = aywk_cookie_set_request();
//    NSMutableString *cookieValue = [NSMutableString stringWithFormat:@""];
//    for (NSString *key in cookies) {
//        NSString *appendString = [NSString stringWithFormat:@"%@=%@;", key, [cookies valueForKey:key]];
//        [cookieValue appendString:appendString];
//    }
//    [request setValue:cookieValue forHTTPHeaderField:@"Cookie"];
//    [webView loadRequest:request];
//    [aywk_cookieDict() setDictionary:cookies];
//    NSLog(@"cookie_setCookie");
//}
//
// void aywk_cleCookie() {
//    NSArray *allKeys = aywk_cookieDict().allKeys;
//    [aywk_cookieDict() removeAllObjects];
//    NSMutableString *cookieValue = [NSMutableString string];
//    for (NSString* key in allKeys) {
//        [cookieValue appendFormat:@"%@=%@;",key,@"nil"];
//    }
//    WKWebView *webView = aywk_webView_processPool();
//    NSMutableURLRequest *request = aywk_cookie_set_request();
//    [request setValue:cookieValue forHTTPHeaderField:@"Cookie"];
//    [webView loadRequest:request];
//    NSLog(@"cookie_cleCookie");
//}
//
// NSMutableURLRequest* aywk_cookie_set_request() {
//    static NSMutableURLRequest *kRequest;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://h5.youzan.com/v2/showcase/homepage?alias=juhos0"]];
//    });
//    return kRequest;
//}
//
//+(void)setCookieWithKey:(NSString*)key value:(NSString*)value {
//    aywk_setCookies(@{key: value?:@"nil"});
//}
//
//+(void)setCookies:(NSDictionary*)cookies {
//    aywk_setCookies(cookies);
//}
//
//+(void)cleCookie {
//    aywk_cleCookie();
//}
//
//@end
//
