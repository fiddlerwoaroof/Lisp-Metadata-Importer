//  NSString_HMext.m
//
//  Created by John Wiseman on 9/6/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import "NSString_HMExt.h"
#import "NSData_HMExt.h"

@implementation NSString (NSString_ParsingExtensions)

/*
 * Returns an NSArray containing substrings from the receiver that have been
 * divided by characters in separatorSet. The substrings in the array appear
 * in the order they did in the receiver.
 *
 * Based on GnuStep's componentsSeparatedByString.
 */
- (NSArray*) componentsSeparatedByCharacterFromSet: (NSCharacterSet*)separatorSet
{
	NSRange search;
	NSRange complete;
	NSRange found;
	NSMutableArray *array = [NSMutableArray array];

	search = NSMakeRange(0, [self length]);
	complete = search;
	found = [self rangeOfCharacterFromSet:separatorSet];
	while (found.length != 0)
    {
		NSRange current;

		current = NSMakeRange(search.location, found.location - search.location);
		[array addObject:[self substringWithRange:current]];

		search = NSMakeRange(found.location + found.length, complete.length - found.location - found.length);
		found = [self rangeOfCharacterFromSet:separatorSet options:0 range:search];
    }
	// Add the last search string range
	[array addObject: [self substringWithRange: search]];

	return array;
}

/**
 * Load up to the first theMaxSize bytes of file at path into a new string.
 */
+ (NSString*)stringWithContentsOfFile:(NSString*)pathToFile maxSize:(int)theMaxSize encoding:(NSStringEncoding)theEncoding error:(NSError**)theError
{
	NSString	*obj;
	
	obj = [self allocWithZone:NSDefaultMallocZone()];
	obj = [obj initWithContentsOfFile:pathToFile maxSize:theMaxSize encoding:theEncoding error:theError];
	return [obj autorelease];
}

/**
 * Initialises the receiver with up to the first maxSize bytes of the
 * file at path.
 *
 * Invokes [NSData-initWithContentsOfFile:maxSize:error:] to read the
 * file, then examines the data to infer its encoding type, and
 * converts the data to a string using -initWithData:encoding:
 *
 * Releases the receiver and returns nil if the file could not be read
 * and converted to a string.
 * 
 */
- (NSString*)initWithContentsOfFile:(NSString*)path maxSize:(int)theMaxSize encoding:(NSStringEncoding)theEncoding error:(NSError**)theError
{
	NSData		*d;
	unsigned int		len;
	const unsigned char	*data_bytes;
	
	d = [[NSData alloc] initWithContentsOfFile:path maxSize:theMaxSize error:theError];
	if (d == nil)
    {
		[self dealloc];
		return nil;
    }
	len = [d length];
	if (len == 0)
    {
		[d release];
		[self dealloc];
		return @"";
    }
	data_bytes = [d bytes];
	
	self = [self initWithData:d encoding:theEncoding];
	[d release];
	return self;
}

@end
