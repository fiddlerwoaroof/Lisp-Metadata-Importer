//  NSString_HMext.h
//
//  Created by John Wiseman on 9/6/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import <Cocoa/Cocoa.h>

@interface NSString (NSString_HMExtensions)

+ (NSString*)stringWithContentsOfFile:(NSString*)pathToFile maxSize:(int)theMaxSize encoding:(NSStringEncoding)theEncoding error:(NSError**)theError;

- (NSArray*)componentsSeparatedByCharacterFromSet:(NSCharacterSet*)set;
- (NSString*)initWithContentsOfFile:(NSString*)pathToFile maxSize:(int)theMaxSize encoding:(NSStringEncoding)theEncoding error:(NSError**)theError;

@end
