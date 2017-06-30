//
//  AYBionicWebView.h
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/20.
//  Copyright © 2017年 ylchun. All rights reserved.
//
//  侧滑前进、后退导航栏跟随效果

#import "AYWKWebView.h"

#define AYWKWebView_bionicEnabled 1 //导航条样式开关，由于涉及私有代理协议，若审核失败改为0即可(项目审核已通过，以防万一)

@interface AYBionicWebView : AYWKWebView

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wobjc-property-synthesis"
@property (nonatomic) BOOL allowsLinkPreview NS_UNAVAILABLE;
//@property (nonatomic) BOOL allowsForwardNavigationGestures NS_UNAVAILABLE;
@property (nonatomic) BOOL allowSelectionGestures NS_UNAVAILABLE;
@property (nonatomic) BOOL allowLongPressGestures NS_UNAVAILABLE;
#pragma clang diagnostic pop

@end
