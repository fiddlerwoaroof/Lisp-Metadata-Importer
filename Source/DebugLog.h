//  DebugLog.h
//
//  Created by John Wiseman on 9/8/05.
//  Copyright 2005 John Wiseman. All rights reserved.

#import <Cocoa/Cocoa.h>


typedef enum {
	DEBUG_LEVEL_VERBOSE = 0,
	DEBUG_LEVEL_DEBUG = 1,
	DEBUG_LEVEL_OFF = 2,
} DebugLevel;

DebugLevel DebugLevelNameToValue(NSString *name);

void SetDebugLogLevel(DebugLevel level);

void DebugLog(DebugLevel level, NSString *format, ...);
