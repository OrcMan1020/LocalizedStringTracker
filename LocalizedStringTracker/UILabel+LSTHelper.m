//
//  UILabel+LSTHelper.m
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import "UILabel+LSTHelper.h"

#import "NSString+LSTHelper.h"
#import "NSObject+LSTHelper.h"
#import <objc/runtime.h>
//#import "UIView+AutomationSupport.h"

BOOL needHighlight = YES;

#define LABEL_LOCALIZED_HIGIHT_DEBUG 1

static void * UILabelLocalizedPropertyKey = &UILabelLocalizedPropertyKey;
static void * CALayerTagPropertyKey = &CALayerTagPropertyKey;


@implementation CALayer (Swizzle)

-(NSUInteger)tag
{
    NSNumber* number = objc_getAssociatedObject(self, CALayerTagPropertyKey);
    return [number unsignedIntegerValue];
    
}

-(void)setTag:(NSUInteger)tag
{
    NSNumber* number = [NSNumber numberWithUnsignedInteger:tag];
    objc_setAssociatedObject(self, CALayerTagPropertyKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UILabel (LSTHelper)


+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        
        // some special case here
        Class UITableViewLabel = NSClassFromString(@"UITableViewLabel");
        [UITableViewLabel swizzleInstanceMethod:@selector(setText:) withMethod:@selector(mySetTextForUITableViewLabel:)];
        
        Class UISegmentLabel = NSClassFromString(@"UISegmentLabel");
        [UISegmentLabel swizzleInstanceMethod:@selector(setText:) withMethod:@selector(mySetTextForUISegmentLabel:)];
        
        
        Class UITextFieldLabel = NSClassFromString(@"UITextFieldLabel");
        Class class = [UILabel class];
        if(class)
        {
            [class swizzleInstanceMethod:@selector(setText:) withMethod:@selector(mySetText:)];
            
//            [self swizzleInstanceMethod:@selector(setAttributedText:) withMethod:@selector(setAttributedTextHook:)];
//            [self swizzleInstanceMethod:@selector(_setAttributedText:andTakeOwnership:) withMethod:@selector(_setAttributedText:andTakeOwnershipHook:)];
            
        }
        
    });
}

-(void)setLocalized:(BOOL)localized
{
    NSNumber* number = [NSNumber numberWithBool:localized];
    objc_setAssociatedObject(self, UILabelLocalizedPropertyKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

-(BOOL)localized
{
    NSNumber* number = objc_getAssociatedObject(self, UILabelLocalizedPropertyKey);
    return [number boolValue];
}


-(void)mySetText:(NSString*)text
{
    self.localized = text.gslocalized;
    
    [self mySetText:text];
    [self highlightBorder];
    
}

-(void)mySetTextForUITableViewLabel:(NSString*)text
{
    self.localized = text.gslocalized;
    
    [self mySetTextForUITableViewLabel:text];
    
    [self highlightBorder];
}

-(void)highlightBorder
{
    if(!needHighlight){
        return;
    }
    
#if LABEL_LOCALIZED_HIGIHT_DEBUG
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if(self.localized){
            
            [weakSelf enableHighlight];
        }
        else {
            
            [weakSelf disableHighlight];
        }
    });
    
#endif
}

//-(void)disableHighlight
//{
//    [super disableHighlight];
//    //    if(self.localized){
//    //        [super disableHighlight];
//    //    }
//}
//
//-(void)enableHighlight
//{
//    
//    [super enableHighlight];
//    //    if(self.localized){
//    //
//    //    }
//}


-(void)disableHighlight
{
    CALayer* layerx = nil;
    for(CALayer* layer in self.layer.sublayers){
        if(layer.tag == 0x19830822){
            layerx = layer;
            break;
        }
    }
    
    [layerx removeFromSuperlayer];
}

-(void)enableHighlight
{
    CALayer* myLayer = nil;
    for(CALayer* layer in self.layer.sublayers){
        if(layer.tag == 0x19830822){
            myLayer = layer;
            break;
        }
        
    }
    
    if (!myLayer){
        myLayer = [[CALayer alloc] init];
        myLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0xff alpha:0.1].CGColor;
        [self.layer addSublayer:myLayer];
        myLayer.tag = 0x19830822;
        
    }
    myLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
}



-(void)mySetTextForUISegmentLabel:(NSString*)text
{
    [self mySetTextForUISegmentLabel:text];
    self.localized = text.gslocalized ;
    
    [self highlightBorder];
}

//-(void)setAttributedTextHook:(NSAttributedString *)attributedText
//{
//    
//    //    if(![self isKindOfClass:NSClassFromString(@"UISegmentLabel")]){
//    self.localized = attributedText.localized;
//    //    }
//    [self setAttributedTextHook:attributedText];
//    
//    [self highlightBorder];
//}

//- (void)_setAttributedText:(id)arg1 andTakeOwnershipHook:(_Bool)arg2
//{
//    [self _setAttributedText:arg1 andTakeOwnershipHook:arg2];
//    NSAttributedString* attrString = (NSAttributedString*)arg1;
//    self.localized = attrString.localized;
//    
//    [self highlightBorder];
//    
//}

@end

