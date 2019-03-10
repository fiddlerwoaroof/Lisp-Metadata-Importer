//  DebugLog.m
//
//  Lisp Metadata Importer
//
//  Created by John Wiseman on 9/8/05.
//  Copyright 2005 John Wiseman. All rights reserved.

#import "DebugLog.h"


static DebugLevel GlobalDebugLevel = DEBUG_LEVEL_OFF;


DebugLevel DebugLevelNameToValue(NSString *name)
{
	DebugLevel level = DEBUG_LEVEL_OFF;
	
	if ([name isEqualToString:@"DEBUG_LEVEL_VERBOSE"])
	{
		level = DEBUG_LEVEL_VERBOSE;
	}
	else if ([name isEqualToString:@"DEBUG_LEVEL_DEBUG"])
	{
		level = DEBUG_LEVEL_DEBUG;
	}
	else if ([name isEqualToString:@"DEBUG_LEVEL_OFF"])
	{
		level = DEBUG_LEVEL_OFF;
	}
	return level;
}

void SetDebugLogLevel(DebugLevel theLevel)
{
	GlobalDebugLevel = theLevel;
}

void DebugLog(DebugLevel level, NSString *format, ...)
{
	if (level >= GlobalDebugLevel)
	{
		// get a reference to the arguments on the stack that follow
		// the format paramter
		va_list argList;
		va_start (argList, format);
		
		// NSString luckily provides us with this handy method which
		// will do all the work for us, including %@
		NSString *string;
		string = [[NSString alloc] initWithFormat: format
										arguments: argList];
		va_end  (argList);
		
		// Log it.
		NSLog(@"%@", string);
		
		[string release];
	}
}

