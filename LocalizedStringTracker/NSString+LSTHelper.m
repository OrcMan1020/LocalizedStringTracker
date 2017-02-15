//
//  NSString+LSTHelper.m
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//
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



@implementation NSMutableString (LSTHelper)
+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSMutableString class];
        
        Class NSCFStringClass = NSClassFromString(@"__NSCFString");
        [NSCFStringClass swizzleInstanceMethod:@selector(appendString:) withMethod:@selector(swizzle_appendString:)];
        [NSCFStringClass swizzleInstanceMethod:@selector(appendFormat:) withMethod:@selector(swizzle_appendFormat:)];
        [NSCFStringClass swizzleInstanceMethod:@selector(insertString:atIndex:) withMethod:@selector(swizzle_insertString:atIndex:)];
        
        [class swizzleInstanceMethod:@selector(appendFormat:) withMethod:@selector(swizzle_appendFormat:)];
        [class swizzleInstanceMethod:@selector(appendString:) withMethod:@selector(swizzle_appendString:)];
        [class swizzleInstanceMethod:@selector(setString:) withMethod:@selector(swizzle_setString:)];
        
    });
}


-(void)swizzle_appendString:(NSString *)aString
{
    [self swizzle_appendString:aString];
    self.gslocalized = self.gslocalized || aString.gslocalized;
}

-(void)swizzle_appendFormat:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString* bString = [[NSString alloc] initWithFormat:format locale:nil arguments:argList];
    va_end(argList);
    
    [self swizzle_appendString:bString];
    self.gslocalized = self.gslocalized || format.gslocalized || bString.gslocalized;
}

-(void)swizzle_insertString:(NSString *)aString atIndex:(NSUInteger)loc
{
    [self swizzle_insertString:aString atIndex:loc];
    
    self.gslocalized = self.gslocalized || aString.gslocalized;
}

-(void)swizzle_setString:(NSString *)aString
{
    [self swizzle_setString:aString];
    self.gslocalized = self.gslocalized || aString.gslocalized;
}

@end


@implementation NSAttributedString (LSTHelper)

static void * AttributeStringLocalizedPropertyKey = &AttributeStringLocalizedPropertyKey;


-(void)setGslocalized:(BOOL)localized
{
    NSNumber* number = [NSNumber numberWithBool:localized];
    objc_setAssociatedObject(self, AttributeStringLocalizedPropertyKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

-(BOOL)gslocalized
{
    NSNumber* number = objc_getAssociatedObject(self, AttributeStringLocalizedPropertyKey);
    return [number boolValue];
}


+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSAttributedString class];
        Class NSConcreteAttributedStringClass = [NSAttributedString alloc].class;//NSClassFromString(@"NSConcreteAttributedString");
        
        [NSConcreteAttributedStringClass swizzleInstanceMethod:@selector(initWithString:attributes:) withMethod:@selector(swizzle_initWithString:attributes:)];
        [NSConcreteAttributedStringClass swizzleInstanceMethod:@selector(initWithString:) withMethod:@selector(swizzle_initWithString:)];
        [NSConcreteAttributedStringClass swizzleInstanceMethod:@selector(initWithAttributedString:) withMethod:@selector(swizzle_initWithAttributedString:)];
        
        [class swizzleInstanceMethod:@selector(string) withMethod:@selector(swizzle_string)];
        [class swizzleInstanceMethod:@selector(copy) withMethod:@selector(swizzle_copy)];
        [class swizzleInstanceMethod:@selector(mutableCopy) withMethod:@selector(swizzle_mutableCopy)];
        //- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range;
        
    });
    
    
}

-(instancetype)swizzle_copy
{
    NSAttributedString* attrStr = [self swizzle_copy];
    attrStr.gslocalized = self.gslocalized;
    
    return attrStr;
}

-(instancetype)swizzle_mutableCopy
{
    NSAttributedString* attrStr = [self swizzle_mutableCopy];
    attrStr.gslocalized = self.gslocalized;
    
    return attrStr;
}

-(instancetype)swizzle_initWithString:(NSString *)str attributes:(NSDictionary<NSString *,id> *)attrs
{
    NSAttributedString* as = [self swizzle_initWithString:str attributes:attrs];
    
    as.gslocalized = str.gslocalized;
    return as;
}

-(instancetype)swizzle_initWithString:(NSString *)str
{
    NSAttributedString* as = [self swizzle_initWithString:str];
    as.gslocalized = str.gslocalized;
    return as;
    
}

-(instancetype)swizzle_initWithAttributedString:(NSAttributedString *)attrStr
{
    NSAttributedString* as = [self swizzle_initWithAttributedString:attrStr];
    as.gslocalized = attrStr.gslocalized;
    return as;
    
}

-(NSString*)swizzle_string
{
    NSString* string = [self swizzle_string];
    string.gslocalized = self.gslocalized;
    return string;
}

- (void)swizzle_appendAttributedString:(NSAttributedString *)attrString
{
    [self swizzle_appendAttributedString:attrString];
    self.gslocalized = self.gslocalized || attrString.gslocalized;
}


@end

@implementation NSMutableAttributedString (LSTHelper)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSMutableAttributedString class];
        Class NSConcreteMutableAttributedStringClass = [NSMutableAttributedString alloc].class;
        [class swizzleInstanceMethod:@selector(appendAttributedString:) withMethod:@selector(swizzle_appendAttributedString:)];
        [class swizzleInstanceMethod:@selector(setAttributedString:) withMethod:@selector(swizzle_setAttributedString:)];
        [NSConcreteMutableAttributedStringClass swizzleInstanceMethod:@selector(initWithString:) withMethod:@selector(swizzle_initWithString:)];
        [NSConcreteMutableAttributedStringClass swizzleInstanceMethod:@selector(initWithString:attributes:) withMethod:@selector(swizzle_initWithString:attributes:)];
        
        // for UISegment
        [NSConcreteMutableAttributedStringClass swizzleInstanceMethod:@selector(string) withMethod:@selector(swizzle_string)];
        
        [class swizzleInstanceMethod:@selector(attributedSubstringFromRange:) withMethod:@selector(swizzle_attributedSubstringFromRange:)];
        
        
    });
}

-(NSAttributedString*)swizzle_attributedSubstringFromRange:(NSRange)range
{
    NSAttributedString* attr = [self swizzle_attributedSubstringFromRange:range];
    attr.gslocalized = self.gslocalized;
    return attr;
}

-(instancetype)swizzle_initWithString:(NSString *)str
{
    NSMutableAttributedString* mas;
    mas = [self swizzle_initWithString:str];
    mas.gslocalized = str.gslocalized;
    
    return mas;
}

-(instancetype)swizzle_initWithString:(NSString *)str attributes:(NSDictionary<NSString *,id> *)attrs
{
    NSMutableAttributedString* mas;
    mas = [self swizzle_initWithString:str attributes:attrs];
    mas.gslocalized = str.gslocalized;
    
    return mas;
}

-(void)swizzle_appendAttributedString:(NSAttributedString *)attrString
{
    [self swizzle_appendAttributedString:attrString];
    self.gslocalized = self.gslocalized || attrString.gslocalized;
}

-(void)swizzle_setAttributedString:(NSAttributedString *)attrString
{
    [self swizzle_setAttributedString:attrString];
    self.gslocalized = attrString.gslocalized;
    
}

-(NSString*)swizzle_string
{
    NSString* s = [self swizzle_string];
    s.gslocalized = self.gslocalized;
    return s;
}

@end

@implementation NSDateFormatter (LSTHelper)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSDateFormatter class];
        
        [class swizzleInstanceMethod:@selector(stringFromDate:) withMethod:@selector(swizzle_stringFromDate:)];
        [class swizzleInstanceMethod:@selector(shortMonthSymbols) withMethod:@selector(swizzle_shortMonthSymbols)];
        [class swizzleInstanceMethod:@selector(shortWeekdaySymbols) withMethod:@selector(swizzle_shortWeekdaySymbols)];
        
        [class swizzleClassMethod:@selector(localizedStringFromDate:dateStyle:timeStyle:) withMethod:@selector(swizzle_localizedStringFromDate:dateStyle:timeStyle:)];
        
        // TODO
        // add more
        
    });
}

-(NSString*)swizzle_stringFromDate:(NSDate*)date
{
    NSString* s = [self swizzle_stringFromDate:date];
    s.gslocalized = YES;
    
    return s;
}

+(NSString*)swizzle_localizedStringFromDate:(NSDate *)date dateStyle:(NSDateFormatterStyle)dstyle timeStyle:(NSDateFormatterStyle)tstyle
{
    NSString* s = [self swizzle_localizedStringFromDate:date dateStyle:dstyle timeStyle:tstyle];
    s.gslocalized = YES;
    
    return s;
}

+(NSString*)swizzle_dateFormatFromTemplate:(NSString *)tmplate options:(NSUInteger)opts locale:(NSLocale *)locale
{
    NSString* s = [self swizzle_dateFormatFromTemplate:tmplate options:opts locale:locale];
    s.gslocalized = YES;
    
    return s;
    
}

-(NSArray<NSString *> *)swizzle_shortMonthSymbols
{
    NSArray<NSString *> *array = [self swizzle_shortMonthSymbols];
    for(NSString* s in array){
        s.gslocalized = YES;
    }
    
    return array;
}


-(NSArray<NSString *> *)swizzle_shortWeekdaySymbols
{
    NSArray<NSString *> *array = [self swizzle_shortWeekdaySymbols];
    for(NSString* s in array){
        s.gslocalized = YES;
    }
    
    return array;
}



@end

@implementation UILocalizedIndexedCollation(LSTHelper)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UILocalizedIndexedCollation class];
        
        [class swizzleInstanceMethod:@selector(sectionTitles) withMethod:@selector(swizzle_sectionTitles)];
        
    });
}

-(NSArray<NSString *> *)swizzle_sectionTitles
{
    NSArray<NSString *> *array = [self swizzle_sectionTitles];
    for(NSString* s in array){
        s.gslocalized = YES;
    }
    
    return array;
}

@end


