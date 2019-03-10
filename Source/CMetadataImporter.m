//  CMetadataImporter.m
//
//  Lisp Metadata Importer
//
//  Created by John Wiseman on 9/1/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import "CMetadataImporter.h"

#import "NSString_HMext.h"
#import "NSData_HMext.h"
#import "DebugLog.h"

@implementation CMetadataImporter


long MaxSourceSize = 500000; // Default maximum number of bytes that will be read for indexing purposes.
long NO_MAXIMUM = -1;


// All sorts of static data that we initialize once, then use many many times.

static BOOL StaticDataIsInitialized = NO;

// Lots of regexes in string form, waiting to be compiled.

static NSString *LispDef1_pat = @"(?i)^\\(def[^\\s]*[\\s\\']+(\\(setf\\s+[^\\s]+\\))";
static AGRegex *LispDef1_RE = nil;

static NSString *LispDef2_pat = @"(?i)^\\(def[^\\s]*[\\s\\']+([^\\s\\)]+)";
static AGRegex *LispDef2_RE = nil;

static NSString *LispDefun_pat = @"(?i)^\\(defun\\s+([^\\s\\)\\(]+)";
static AGRegex *LispDefun_RE = nil;

static NSString *LispDefunsetf_pat = @"(?i)^\\(defun\\s+(\\(setf\\s+[^\\s]+\\))";
static AGRegex *LispDefunsetf_RE = nil;

static NSString *LispDefmethod_pat = @"(?i)^\\(defmethod\\s+([^\\s\\)\\(]+)";
static AGRegex *LispDefmethod_RE = nil;

static NSString *LispDefmethodsetf_pat = @"(?i)^\\(defmethod\\s+(\\(setf\\s+[^\\s]+\\))";
static AGRegex *LispDefmethodsetf_RE = nil;

static NSString *LispDefgeneric_pat = @"(?i)^\\(defgeneric\\s+((?:[^\\s\\)\\(]+|\\(setf\\s+[^\\s]+\\)))";
static AGRegex *LispDefgeneric_RE = nil;

static NSString *LispDefgenericsetf_pat = @"(?i)^\\(defgeneric\\s+(\\(setf\\s+[^\\s]+\\))";
static AGRegex *LispDefgenericsetf_RE = nil;

static NSString *LispDefmacro_pat = @"(?i)^\\(defmacro\\s+([^\\s\\)]+)";
static AGRegex *LispDefmacro_RE = nil;

static NSString *LispDefclass_pat = @"(?i)^\\(defclass\\s+([^\\s\\)]+)";
static AGRegex *LispDefclass_RE = nil;

static NSString *LispDefstruct_pat = @"(?i)^\\(defstruct\\s+\\(?([^\\s\\)]+)";
static AGRegex *LispDefstruct_RE = nil;

static NSString *LispDefvar_pat = @"(?i)^\\((?:defvar|defparameter|defconstant)\\s+([^\\s\\)]+)";
static AGRegex *LispDefvar_RE = nil;



- (void)initStaticData
{
    NSLog(@"Import Lisp");
	if (StaticDataIsInitialized)
	{
		return;
	}
	
	StaticDataIsInitialized = YES;
	
	// Find the bundle, and Info.plist.  Set the debug level specified
	// there, as well as the maximum file length to index.
	NSBundle *theBundle = [NSBundle bundleForClass:[self class]];
	
	NSObject *debugLevelObj = [theBundle objectForInfoDictionaryKey:@"DebugLevel"];
	if (debugLevelObj != nil)
	{
		SetDebugLogLevel(DebugLevelNameToValue((NSString*)debugLevelObj));
	}

	NSObject *maxSourceSizeObj = [theBundle objectForInfoDictionaryKey:@"MaxSourceSizeToIndex"];
	int max = [(NSNumber*)maxSourceSizeObj intValue];
	if (max != 0)
	{
		DebugLog(DEBUG_LEVEL_DEBUG, @"Using MaxSourceSize=%d", max);
		MaxSourceSize = max;
	}
	else
	{
		NSLog(@"Error parsing MaxSourceSizeToIndex, using %d", MaxSourceSize);
	}
	
	// Precompile our regexes.
	LispDef1_RE = [[AGRegex alloc] initWithPattern:LispDef1_pat];
	LispDef2_RE = [[AGRegex alloc] initWithPattern:LispDef2_pat];
	LispDefun_RE = [[AGRegex alloc] initWithPattern:LispDefun_pat];
	LispDefunsetf_RE = [[AGRegex alloc] initWithPattern:LispDefunsetf_pat];
	LispDefmethod_RE = [[AGRegex alloc] initWithPattern:LispDefmethod_pat];
	LispDefmethodsetf_RE = [[AGRegex alloc] initWithPattern:LispDefmethodsetf_pat];
	LispDefgeneric_RE = [[AGRegex alloc] initWithPattern:LispDefgeneric_pat];
	LispDefgenericsetf_RE = [[AGRegex alloc] initWithPattern:LispDefgenericsetf_pat];
	LispDefclass_RE = [[AGRegex alloc] initWithPattern:LispDefclass_pat];
	LispDefstruct_RE = [[AGRegex alloc] initWithPattern:LispDefstruct_pat];
	LispDefvar_RE = [[AGRegex alloc] initWithPattern:LispDefvar_pat];
	LispDefmacro_RE = [[AGRegex alloc] initWithPattern:LispDefmacro_pat];
	
	DebugLog(DEBUG_LEVEL_DEBUG, @"Static data has been initialized.");
}



static NSStringEncoding PossibleSourceTextEncodings[] = {	NSUTF8StringEncoding,
															NSMacOSRomanStringEncoding,
															NSISOLatin1StringEncoding,
															NSWindowsCP1252StringEncoding };

// Tries to read the file using the encodings specified in
// PossibleSourceTextEncodings, in order, until one succeeds.
//
// There's probably a better way to do this (TEC Sniffers?).  The
// seemingly obvious way, stringWithContentsOfFile:usedEncoding:error,
// doesn't work--apparently it just does something minimal, like
// decide between UTF-8 and UCS-16 or something.

- (NSString*)readContentsOfFile:(NSString*)pathToFile error:(NSError**)theError
{
	int i;
	NSStringEncoding theEncoding;
	NSString *theSource = nil;
	NSData *data;
	
	DebugLog(DEBUG_LEVEL_DEBUG, @"Indexing %@", pathToFile);
	
	// Read the file.
	if (MaxSourceSize == NO_MAXIMUM)
	{
		data = [NSData dataWithContentsOfFile:pathToFile options:0 error:theError];
	}
	else
	{
		data = [NSData dataWithContentsOfFile:pathToFile maxSize:MaxSourceSize error:theError];
		if ([data length] == MaxSourceSize)
		{
			// This is not absolutely certain to be correct, since the file might just have been
			// MaxSourceSize bytes long.
			DebugLog(DEBUG_LEVEL_DEBUG, @"Truncated indexing of '%@' to %d bytes", pathToFile, MaxSourceSize);
		}
	}
	
	if (data == nil)
	{
		return nil;
	}
	
	// Try to convert the file contents to a string by trying the candidate
	// encodings, in order.
	for (i = 0; i < sizeof(PossibleSourceTextEncodings); i++)
	{
		theEncoding = PossibleSourceTextEncodings[i];
		DebugLog(DEBUG_LEVEL_VERBOSE, @"Trying encoding %d", theEncoding);
		theSource = [[[NSString alloc] initWithData:data encoding:theEncoding] autorelease];
		if (theSource != nil)
		{
			break;
		}
		else
		{
			DebugLog(DEBUG_LEVEL_DEBUG, @"Reading with encoding %d failed.", theEncoding);
		}
	}
	return theSource;
}


// Adds metadata values to the specified dictionary under the
// specified key, using the specified regular expression.

- (BOOL)addMatchesTo:(NSMutableDictionary *)attributes fromLine:(NSString *)line usingRE:(AGRegex *)regex forKey:(NSString *)key
{
	AGRegexMatch *match = [regex findInString:line];
	if (match)
	{
		NSString *name = [match groupAtIndex: 1];
		[[attributes objectForKey:key] addObject:name];
		return YES;
	}
	else
	{
		return NO;
	}
}


// This is the method that does all the importing and indexing work.
// It stuffs attributes into the specified dictionary.

- (BOOL)importFile:(NSString *)inPathToFile contentType:(NSString *)inContentType attributes:(NSMutableDictionary *)inAttributes
{
	BOOL theResult = NO;
	
	@try
	{
		NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		NSString *source;
		
		[self initStaticData];
		
		source = [self readContentsOfFile:inPathToFile error:&error];
		if (source == nil)
		{
			if (error)
			{
				NSLog(@"Lisp Metadata Importer: Could not process file '%@': %@", inPathToFile, error);
			}
			else
			{
				NSLog(@"Lisp Metadata Importer: Could not process file '%@': unknown error", inPathToFile);
			}	
			return NO;
		}
		
		// Only process the first MaxSourceSize of the file.  To try to do more
		// invites the swapping death.
		if ([source length] > MaxSourceSize)
		{
			source = [source substringToIndex:MaxSourceSize];
		}
		
		NSMutableDictionary *moreAttributes = [[[NSMutableDictionary alloc] initWithCapacity:10] autorelease];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_definitions"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defuns"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defmethods"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defgenerics"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defmacros"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defvars"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defclasses"];
		[moreAttributes setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"org_lisp_defstructs"];
		
		
		// Divide the file contents into lines, using either CR or LF to end a line.
		NSCharacterSet *eol = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
		NSArray *lines = [source componentsSeparatedByCharacterFromSet:eol];
		
		NSEnumerator *theEnum = [lines objectEnumerator];
		NSString *theLine;
		
		while (nil != (theLine = [theEnum nextObject]))
		{
			// The following check speeds the indexer up by roughly 6x.
			if (([theLine length] > 0) && ([theLine characterAtIndex:0] == '('))
			{
				if (![self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDef1_RE forKey:@"org_lisp_definitions"])
				{
					// The first expression didn't fire, try the second one.
					[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDef2_RE forKey:@"org_lisp_definitions"];
				}
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefun_RE forKey:@"org_lisp_defuns"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefunsetf_RE forKey:@"org_lisp_defuns"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefmethod_RE forKey:@"org_lisp_defmethods"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefmethodsetf_RE forKey:@"org_lisp_defmethods"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefgeneric_RE forKey:@"org_lisp_defgenerics"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefgenericsetf_RE forKey:@"org_lisp_defgenerics"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefmacro_RE forKey:@"org_lisp_defmacros"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefvar_RE forKey:@"org_lisp_defvars"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefclass_RE forKey:@"org_lisp_defclasses"];
				[self addMatchesTo:moreAttributes fromLine:theLine usingRE:LispDefstruct_RE forKey:@"org_lisp_defstructs"];
			}
			
		}
		
		// Add the complete source code as metadata.
		[moreAttributes setObject:source forKey:@"kMDItemTextContent"];
		
		[inAttributes addEntriesFromDictionary:moreAttributes];
		theResult = YES;
		[theAutoreleasePool release];
	}
	@catch (NSException *localException)
	{
		NSLog(@"Lisp Metadata Importer: Could not process file '%@' (Exception: %@)", inPathToFile, localException);
	}
	@finally
	{
	}
	return(theResult);
}

@end
