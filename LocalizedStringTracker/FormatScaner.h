//
//  FormatScaner.h
//  CmdlineProgram
//
//  Created by saix on 16/11/19.
//  Copyright © 2016年 citrix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormatScaner : NSObject

+(NSArray*)scanWithFormat:(NSString*)format andOutput:(NSMutableArray*)outputArray, ...;
+(NSArray*)scanWithFormat:(NSString*)format locale:(NSDictionary*)locale arguments: (va_list)argList andOutput:(NSMutableArray*)outputArray;
@end
