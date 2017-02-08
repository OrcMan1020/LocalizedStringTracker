//
//  UILabel+LSTHelper.h
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (LSTHelper)

@property (nonatomic) BOOL localized;
-(void)enableHighlight;
-(void)disableHighlight;

@end
@interface CALayer (Swizzle)

@property (nonatomic) NSUInteger tag;

@end

