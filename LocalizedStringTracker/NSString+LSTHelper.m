//
//  NSString+LSTHelper.m
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import "NSString+LSTHelper.h"

#import <objc/runtime.h>
#import "FormatScaner.h"
#import "NSObject+LSTHelper.h"

static void * StringLocalizedPropertyKey = &StringLocalizedPropertyKey;
static void * StringNativePropertyKey = &StringNativePropertyKey;


@implementation NSString (LSTHelper)


-(void)setGslocalized:(BOOL)localized
{
    NSNumber* number = [NSNumber numberWithBool:localized];
    objc_setAssociatedObject(self, StringLocalizedPropertyKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

-(BOOL)gslocalized
{
    NSNumber* number = objc_getAssociatedObject(self, StringLocalizedPropertyKey);
    return [number boolValue];
}


-(NSString*)nativeString
{
    NSString* nativeString = objc_getAssociatedObject(self, StringNativePropertyKey);
    return nativeString;
    
}

-(void)setNativeString:(NSString *)nativeString
{
    objc_setAssociatedObject(self, StringNativePropertyKey, nativeString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSString class];
        
        Class NSPlaceholderStringClass = NSClassFromString(@"NSPlaceholderString");
//        Class NSCFConstantStringClass = NSClassFromString(@"__NSCFConstantString");
//        Class NSCFStringClass = NSClassFromString(@"__NSCFString");
//        Class NSTaggedPointerStringClass = NSClassFromString(@"NSTaggedPointerString");

        [NSPlaceholderStringClass swizzleInstanceMethod:@selector(initWithFormat:locale:arguments:) withMethod:@selector(swizzle_initWithFormat:locale:arguments:)];
        [NSPlaceholderStringClass swizzleInstanceMethod:@selector(initWithString:) withMethod:@selector(swizzle_initWithString:)];
        [NSPlaceholderStringClass swizzleInstanceMethod:@selector(stringByAppendingString:) withMethod:@selector(swizzle_stringByAppendingString:)];
        [NSPlaceholderStringClass swizzleInstanceMethod:@selector(stringByAppendingFormat:) withMethod:@selector(swizzle_stringByAppendingFormat:)];
        
        
        [class swizzleInstanceMethod:@selector(init) withMethod:@selector(swizzle_init)];
        [class swizzleInstanceMethod:@selector(copy) withMethod:@selector(swizzle_copy)];
        [class swizzleInstanceMethod:@selector(mutableCopy) withMethod:@selector(swizzle_mutableCopy)];
        
        [class swizzleInstanceMethod:@selector(stringByAppendingString:) withMethod:@selector(swizzle_stringByAppendingString:)];
        [class swizzleInstanceMethod:@selector(stringByAppendingFormat:) withMethod:@selector(swizzle_stringByAppendingFormat:)];
        
        [class swizzleInstanceMethod:@selector(uppercaseString) withMethod:@selector(swizzle_uppercaseString)];
        [class swizzleInstanceMethod:@selector(lowercaseString) withMethod:@selector(swizzle_lowercaseString)];
        [class swizzleInstanceMethod:@selector(capitalizedString) withMethod:@selector(swizzle_capitalizedString)];
        
        [class swizzleInstanceMethod:@selector(uppercaseStringWithLocale:) withMethod:@selector(swizzle_uppercaseStringWithLocale:)];
        [class swizzleInstanceMethod:@selector(lowercaseStringWithLocale:) withMethod:@selector(swizzle_lowercaseStringWithLocale:)];
        [class swizzleInstanceMethod:@selector(capitalizedStringWithLocale:) withMethod:@selector(swizzle_capitalizedStringWithLocale:)];
        
        [class swizzleClassMethod:@selector(stringWithFormat:) withMethod:@selector(swizzle_stringWithFormat:)];
        
        //TODO
        // add more
    });
    
}

#pragma - mark class method

+(instancetype)swizzle_stringWithFormat:(NSString*)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString* string = [[self alloc] initWithFormat:format locale:nil arguments:argList];
    va_end(argList);
    
    return string;
    
}

+(instancetype)swizzle_stringWithString:(NSString*)string
{
    NSString* result = [self swizzle_stringWithString:string];
    result.gslocalized = string.gslocalized;
    
    return result;
}



#pragma - mark instance method

-(instancetype)swizzle_init
{
    NSString* s = [self swizzle_init];
    self.gslocalized = NO;
    
    return s;
}

-(instancetype)swizzle_initWithFormat:(NSString*)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString* s = [self initWithFormat:format locale:nil arguments:argList];
    va_end(argList);
    
    return s;
}

-(instancetype)swizzle_initWithFormat:(NSString *)format locale:(nullable id)locale, ...
{
    va_list argList;
    va_start(argList, locale);
    NSString* s = [self initWithFormat:format locale:locale arguments:argList];
    va_end(argList);
    
    return s;
}

-(instancetype)swizzle_initWithFormat:(NSString *)format locale:(nullable id)locale arguments:(va_list)argList
{
    va_list copyedArgList;
    va_copy(copyedArgList, argList);
    
    NSString* newString = [self swizzle_initWithFormat:format locale:locale arguments:argList];
    if(format.gslocalized){
        newString.gslocalized = YES;
    }
    else {
        NSMutableArray* output = [[NSMutableArray alloc] init];
        NSArray* strings = [FormatScaner scanWithFormat:format locale:nil arguments:copyedArgList andOutput:output];
        for(NSString* s in strings){
            if(s.gslocalized){
                newString.gslocalized = YES;
                break;
            }
        }
    }
    
    return newString;
}


-(instancetype)swizzle_initWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString* s = [self initWithFormat:format locale:nil arguments:argList];
    return s;
    
}

-(instancetype)swizzle_initWithString:(NSString*)aString
{
    NSString* s = [self swizzle_initWithString:aString];
    s.gslocalized = aString.gslocalized;
    
    return s;
}

-(instancetype)swizzle_initWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
    NSString* s = [self swizzle_initWithData:data encoding:encoding];
    return s;
}

-(NSString*)swizzle_stringByAppendingString:(NSString *)aString
{
    NSString* bString = [self swizzle_stringByAppendingString:aString];
    
    bString.gslocalized = aString.gslocalized || self.gslocalized;
    
    return bString;
}

-(NSString*)swizzle_stringByAppendingFormat:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString* aString = [[NSString alloc] initWithFormat:format locale:nil arguments:argList];
    va_end(argList);
    
    return [self stringByAppendingString:aString];
}

//-(NSString*)stringByPaddingToLength:(NSUInteger)newLength withString:(NSString *)padString startingAtIndex:(NSUInteger)padIndex
//{
//    NSString* rString = [self stringByPaddingToLength:newLength withString:padString startingAtIndex:padIndex];
//}

//-(NSString*)stringByReplacingOccurrencesOfStringHook:(NSString *)target withString:(NSString *)replacement
//{
//
//}

-(NSString*)swizzle_stringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
    NSString* s = [self swizzle_stringByTrimmingCharactersInSet:set];
    s.gslocalized = self.gslocalized;
    
    return s;
}

-(NSString*)swizzle_uppercaseString
{
    NSString* s = [self swizzle_uppercaseString];
    s.gslocalized = self.gslocalized;
    
    return s;
    
}
-(NSString*)swizzle_lowercaseString
{
    NSString* s = [self swizzle_lowercaseString];
    s.gslocalized = self.gslocalized;
    
    return s;
}

-(NSString*)swizzle_capitalizedString
{
    NSString* s = [self swizzle_capitalizedString];
    s.gslocalized = self.gslocalized;
    
    return s;
}


- (NSString *)swizzle_uppercaseStringWithLocale:(nullable NSLocale *)locale
{
    NSString* s = [self swizzle_uppercaseStringWithLocale:locale];
    s.gslocalized = self.gslocalized;
    
    return s;
}
- (NSString *)swizzle_lowercaseStringWithLocale:(nullable NSLocale *)locale
{
    NSString* s = [self swizzle_lowercaseStringWithLocale:locale];
    s.gslocalized = self.gslocalized;
    
    return s;
}
- (NSString *)swizzle_capitalizedStringWithLocale:(nullable NSLocale *)locale
{
    NSString* s = [self swizzle_capitalizedStringWithLocale:locale];
    s.gslocalized = self.gslocalized;
    
    return s;
}

-(id)swizzle_copy
{
    NSString* s = [self swizzle_copy];
    s.gslocalized = self.gslocalized;
    
    return s;
}

-(id)swizzle_mutableCopy
{
    NSMutableString* s = [self swizzle_mutableCopy];
    s.gslocalized = self.gslocalized;
    
    return s;
}






@end
