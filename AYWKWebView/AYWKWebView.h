//
//  AYWKWebView.h
//  AYWKWebView
//
//  Created by YLCHUN on 2017/5/27.
//  Copyright © 2017年 ylchun. All rights reserved.
//
//  UrlSchemes、OpenUrl超链处理，https默认处理，页面常用手势（前进，后退，长按，选择）属性控制，常用观察者属性进行代理获取，截屏操作，3DTauch版本控制，post请求，本地文件

#import <WebKit/WebKit.h>

@protocol AYWKObserverDelegate <NSObject>

@optional

-(void)webView:(WKWebView *)webView estimatedProgress:(double)progress;

-(void)webView:(WKWebView *)webView canGoBackChange:(BOOL)canGoBack;

-(void)webView:(WKWebView *)webView canGoForwardChange:(BOOL)canGoForward;

-(void)webView:(WKWebView *)webView titleChange:(NSString*)title;

-(void)webView:(WKWebView *)webView urlChange:(NSURL*)url;

-(void)webView:(WKWebView *)webView loadingChange:(BOOL)loading;

-(void)webView:(WKWebView *)webView certificateChainChange:(NSString*)certificateChain;

-(void)webView:(WKWebView *)webView hasOnlySecureContentChange:(BOOL)hasOnlySecureContent;

@end

@interface AYWKWebView : WKWebView

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wobjc-property-synthesis"

@property (nonatomic) BOOL allowsBackForwardNavigationGestures NS_UNAVAILABLE;
@property (nonatomic) BOOL allowsLinkPreview;
#pragma clang diagnostic pop

@property (nonatomic, weak) id <AYWKObserverDelegate> observerDelegate;

@property (nonatomic) BOOL allowsBackNavigationGestures;
@property (nonatomic) BOOL allowsForwardNavigationGestures;

@property (nonatomic) BOOL allowSelectionGestures;
@property (nonatomic) BOOL allowLongPressGestures;

-(id)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString;

-(UIImage*)screenshot;
+ (void)clearCache;
@end
