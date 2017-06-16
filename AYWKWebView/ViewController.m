//
//  ViewController.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/16.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "ViewController.h"
#import "AYWKWebView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    AYWKWebView *webView = [[AYWKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    
    webView.allowsBackNavigationGestures = YES;
    webView.allowsForwardNavigationGestures = NO;
    webView.allowSelectionGestures = NO;
    webView.allowLongPressGestures = NO;
    webView.allowsLinkPreview = NO;
    
    [self.view insertSubview:webView atIndex:0];
    
    NSURL *url_net = [NSURL URLWithString:@"https://www.baidu.com"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.html" ofType:nil];
    NSURL *url_path = [NSURL URLWithString:path];

    NSURLRequest *request = [NSURLRequest requestWithURL:url_path];
    [webView loadRequest:request];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
