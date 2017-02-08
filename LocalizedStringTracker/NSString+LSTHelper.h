//
//  NSString+LSTHelper.h
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//  Copyright © 2017年 orcman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LSTHelper)

@property (nonatomic) BOOL gslocalized;
@property (nonatomic) NSString* nativeString;

@end

@interface NSMutableString (LSTHelper)

@end


//@interface NSAttributedString (LSTHelper)
//
//@property (nonatomic) BOOL localized;
//
//
//@end
//
//
//@interface NSMutableAttributedString (LSTHelper)
//
//@end
//
//@interface NSDateFormatter (LSTHelper)
//
//@end
//
//@interface UILocalizedIndexedCollation(LSTHelper)
//
//@end
