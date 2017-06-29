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

    NSArray *oItems = self.navigationController.navigationBar.items;
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@""];
    
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initBackItemWithTitle:@"    " target:nil action:nil];
    item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"tool" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.items = [NSArray arrayWithObject:item];

//    return;

    self.navigationController.navigationBar.translucent = NO;
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    AYBionicWebView *webView = [[AYBionicWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    self.webView = webView;
    webView.allowsBackNavigationGestures = YES;
    webView.observerDelegate = self;
    webView.navigationDelegate = self;
    
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView titleChange:(NSString *)title {
//    self.title = title;
//    self.webView.nTitle = title;
//    if (self.webView.canUpdateNavigationItem) {
//        self.navigationController.navigationBar.items.lastObject.title = title;
//    }
}
//-(void)webView:(WKWebView *)webView urlChange:(NSURL *)url {
//    if (self.webView.canUpdateNavigationItem) {
//        if ([url.absoluteString  isEqualToString:self.webView.backForwardList.currentItem.URL.absoluteString]) {
//            self.webView.navigationItem.title = self.webView.backForwardList.currentItem.title;
//        }else{
//            NSLog(@"");
//        }
//    }else{
//        
//    }
//}
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
