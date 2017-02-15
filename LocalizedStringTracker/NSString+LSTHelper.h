//
//  NSString+LSTHelper.h
//  LocalizedStringTracker
//
//  Created by saix on 2017/2/8.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (LSTHelper)

@property (nonatomic) BOOL gslocalized;
@property (nonatomic) NSString* nativeString;

@end

@interface NSMutableString (LSTHelper)

@end


@interface NSAttributedString (LSTHelper)

@property (nonatomic) BOOL gslocalized;


@end


@interface NSMutableAttributedString (LSTHelper)

@end

@interface NSDateFormatter (LSTHelper)

@end

@interface UILocalizedIndexedCollation(LSTHelper)

@end
