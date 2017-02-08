//
//  NSObject+LSTHelper.m
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import "NSObject+LSTHelper.h"
#import <objc/runtime.h>



@implementation NSObject (LSTHelper)

+ (void)swizzleClassMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class class = [self class];
    
    Method originalMethod = class_getClassMethod(class, origSelector);
    Method swizzledMethod = class_getClassMethod(class, newSelector);
    
    Class metacls = objc_getMetaClass(NSStringFromClass(class).UTF8String);
    if (class_addMethod(metacls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        /* swizzing super class method, added if not exist */
        class_replaceMethod(metacls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, origSelector);
    Method swizzledMethod = class_getInstanceMethod(class, newSelector);
    
    if (class_addMethod(class,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        /*swizzing super class instance method, added if not exist */
        class_replaceMethod(class,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@end
