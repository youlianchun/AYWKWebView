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
@property (nonatomic, strong) AYWKWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *newItem = [[UIBarButtonItem alloc] initWithTitle:@"new" style:UIBarButtonItemStylePlain target:self action:@selector(newItemAction)];
    UIBarButtonItem *coocieItem = [[UIBarButtonItem alloc] initWithTitle:@"cookie" style:UIBarButtonItemStylePlain target:self action:@selector(coocieItemAction)];

    self.navigationItem.rightBarButtonItems = @[newItem, coocieItem];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    AYWKWebView *webView = [[AYWKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    self.webView = webView;
    webView.allowsBackNavigationGestures = YES;
    webView.allowsForwardNavigationGestures = NO;
//    webView.allowSelectionGestures = NO;
//    webView.allowLongPressGestures = NO;
    webView.allowsLinkPreview = NO;
    
    [self.view insertSubview:webView atIndex:0];
    
// //自定义长按手势
//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//    longPress.minimumPressDuration = 1;
//    longPress.delegate = (id<UIGestureRecognizerDelegate>)self;
//    [webView addGestureRecognizer:longPress];
    
    
    NSURL *url_net = [NSURL URLWithString:@"https://www.baidu.com"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.html" ofType:nil];
    NSURL *url_path = [NSURL URLWithString:path];

    NSURLRequest *request = [NSURLRequest requestWithURL:url_net];
    [webView loadRequest:request];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (NSString *)uuid {
    uuid_t uuid;
    uuid_generate(uuid);
    char buffer[37] = {0};
    uuid_unparse_upper(uuid, buffer);
    return [[NSString stringWithUTF8String:buffer] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}
-(void)newItemAction {
    ViewController *vc = [[ViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)coocieItemAction {
//    document.cookie
   id cookie = [self.webView stringByEvaluatingJavaScriptFromString:@"document.cookie"];
    NSLog(@"%@", cookie);
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;//同时响应其它手势
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;//和其它手势冲突时候屏蔽其它手势
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            AYWKWebView *webView = (AYWKWebView*)sender.view;
            CGPoint touchPoint = [sender locationInView:webView];
            NSString *jsCode = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src = '%@'", touchPoint.x, touchPoint.y, @"https://ss0.bdstatic.com/5aV1bjqh_Q23odCf/static/superman/img/logo_top_ca79a146.png"];
            [webView stringByEvaluatingJavaScriptFromString:jsCode];
        }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        default:
            break;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
