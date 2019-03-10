//  NSData_HMext.h
//
//  Created by John Wiseman on 9/6/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import <Cocoa/Cocoa.h>

@interface NSData (NSData_HMExtensions)

+ (id) dataWithContentsOfFile:(NSString*)path maxSize:(int)theMaxSize error:(NSError**)error;
- (id) initWithContentsOfFile:(NSString*)path maxSize:(int)theMaxSize error:(NSError**)error;

@end
