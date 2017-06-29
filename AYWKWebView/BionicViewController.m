//
//  BionicViewController.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "BionicViewController.h"
#import "AYBionicWebView.h"
#import "UIBarButtonItem+Back.h"

@interface BionicViewController ()<AYWKObserverDelegate>
@property (nonatomic, strong)AYBionicWebView *webView;
@end

@implementation BionicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
    
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initBackItemWithTitle:@"    " target:nil action:nil];
    item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"tool" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.items = [NSArray arrayWithObject:item];


    self.navigationController.navigationBar.translucent = NO;
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    AYBionicWebView *webView = [[AYBionicWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    self.webView = webView;
    webView.allowsBackNavigationGestures = YES;
    
    [self.view insertSubview:webView atIndex:0];

    NSURL *url_net = [NSURL URLWithString:@"https://www.baidu.com"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.html" ofType:nil];
    NSURL *url_path = [NSURL URLWithString:path];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url_net];
    [webView loadRequest:request];


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
