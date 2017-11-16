//
//  aywkw_objc.m
//  AYWKWebView
//
//  Created by YLCHUN on 2017/11/15.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "aywkw_objc.h"

void aywkobjc_setAssociated(id target, SEL property, id value , BOOL retain) {
    objc_setAssociatedObject(target, property, value, retain?OBJC_ASSOCIATION_RETAIN_NONATOMIC:OBJC_ASSOCIATION_ASSIGN);
}

id aywkobjc_getAssociated(id target, SEL property) {
    return objc_getAssociatedObject(target, property);
}

void aywkw_setAssociated(id target, NSString *propertyName, id value , BOOL retain) {
    objc_setAssociatedObject(target, NSSelectorFromString(propertyName), value, retain?OBJC_ASSOCIATION_RETAIN_NONATOMIC:OBJC_ASSOCIATION_ASSIGN);
}

id aywkw_getAssociated(id target, NSString *propertyName) {
    return objc_getAssociatedObject(target, NSSelectorFromString(propertyName));
}

void aywkw_replaceMethod(Class cls, SEL originSelector, SEL newSelector) {
    Method oriMethod = class_getInstanceMethod(cls, originSelector);
    Method newMethod = class_getInstanceMethod(cls, newSelector);
    BOOL isAddedMethod = class_addMethod(cls, originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod(cls, newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

BOOL aywk_addMethod(Class cls, SEL aSelector ,const char * encode ,id block) {
    IMP imp = imp_implementationWithBlock(block);
    return class_addMethod(cls, aSelector, imp, encode);
}


