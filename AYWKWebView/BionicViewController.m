//
//  BionicViewController.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "BionicViewController.h"
#import "AYBionicWebView.h"

@interface BionicViewController ()<AYWKObserverDelegate>

@end

@implementation BionicViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.translucent = NO;
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    AYBionicWebView *webView = [[AYBionicWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    
    webView.allowsBackNavigationGestures = YES;
    webView.observerDelegate = self;
    [self.view insertSubview:webView atIndex:0];

    NSURL *url_net = [NSURL URLWithString:@"https://www.baidu.com"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.html" ofType:nil];
    NSURL *url_path = [NSURL URLWithString:path];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url_net];
    [webView loadRequest:request];

    
//    CGRect frame = self.view.bounds;
//    frame.size.width /= 2.0;
//    frame.origin.x += frame.size.width;
//    UIView *view = [[UIView alloc] initWithFrame:frame];
//    view.backgroundColor = [UIColor redColor];
//    view.alpha = 0.5;
//    [self.view addSubview:view];
    // Do any additional setup after loading the view.
}


-(void)webView:(WKWebView *)webView titleChange:(NSString *)title {
    self.title = title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
