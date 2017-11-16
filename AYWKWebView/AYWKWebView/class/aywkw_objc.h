//
//  aywkw_objc.h
//  AYWKWebView
//
//  Created by YLCHUN on 2017/11/15.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

//#ifdef __cplusplus
//extern "C" {
//#endif
    void aywkobjc_setAssociated(id _Nonnull target, SEL property, id value , BOOL retain);

    id aywkobjc_getAssociated(id _Nonnull target, SEL property);

    void aywkw_setAssociated(id _Nonnull target, NSString *propertyName, id value , BOOL retain);

    id aywkw_getAssociated(id _Nonnull target, NSString *propertyName);

    void aywkw_replaceMethod(Class cls, SEL originSelector, SEL newSelector);
    
    BOOL aywk_addMethod(Class cls, SEL aSelector ,const char * encode ,id _Nonnull block);
    
//#ifdef __cplusplus
//}
//#endif

