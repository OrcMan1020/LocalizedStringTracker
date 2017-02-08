//
//  NSBundle+LSTHelper.m
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import "NSBundle+LSTHelper.h"
#import "NSObject+LSTHelper.h"
#import "NSString+LSTHelper.h"

@implementation NSBundle (LSTHelper)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [NSBundle class];
        [class swizzleInstanceMethod:@selector(localizedStringForKey:value:table:) withMethod:@selector(swizzle_localizedStringForKey:value:table:)];
    });
}

- (NSString *)swizzle_localizedStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)tableName
{
    NSString* localizedString = [self swizzle_localizedStringForKey:key value:value table:tableName];
    //    localizedString.nativeString = [enResourceBundle my_localizedStringForKey:key value:value table:tableName];
    localizedString.gslocalized = YES;
    return localizedString;
}




@end
