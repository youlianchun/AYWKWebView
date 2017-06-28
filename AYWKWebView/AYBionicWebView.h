//
//  AYBionicWebView.h
//  AYWKWebView
//
//  Created by YLCHUN on 2017/6/28.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYWKWebView.h"

@interface AYBionicWebView : AYWKWebView

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wobjc-property-synthesis"
@property (nonatomic) BOOL allowsLinkPreview NS_UNAVAILABLE;
@property (nonatomic) BOOL allowsForwardNavigationGestures NS_UNAVAILABLE;
@property (nonatomic) BOOL allowSelectionGestures NS_UNAVAILABLE;
@property (nonatomic) BOOL allowLongPressGestures NS_UNAVAILABLE;
#pragma clang diagnostic pop

@end
