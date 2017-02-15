//
//  FormatScaner.h
//  More detail please see GNUStep
//
//  Created by saix on 16/11/19.
//

#import <Foundation/Foundation.h>

@interface FormatScaner : NSObject

+(NSArray*)scanWithFormat:(NSString*)format andOutput:(NSMutableArray*)outputArray, ...;
+(NSArray*)scanWithFormat:(NSString*)format locale:(NSDictionary*)locale arguments: (va_list)argList andOutput:(NSMutableArray*)outputArray;
@end
