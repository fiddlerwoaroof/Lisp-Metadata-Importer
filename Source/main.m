//  main.m
//
//  Lisp Metadata Importer
//
//  Created by John Wiseman on 9/5/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import "CMetadataImporter.h"
#import "DebugLog.h"


void Log(NSString *format, ...)
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

    // send it to standard out.
    printf("%s\n", [string UTF8String]);

    [string release];

}

void printUsage(const char *progname)
{
	printf("Usage: %s [-noprint] <file 1> <file 2>...\n", progname);
	printf("List Metadata Importer Test tool\n\n");
	printf("Processes the specified files as Lisp source files and extracts and\n");
	printf("prints the metadata attributes that the Lisp Metadata Importer plugin\n");
	printf("would find.\n\n");
	printf("options:  -noprint    Do not print metadata (useful if you want to do\n");
	printf("                      timing bechmarks).\n");
}

void printAttributes(NSDictionary *attributes)
{
	NSEnumerator *keyEnum = [attributes keyEnumerator];
	NSString *key;
	
	while (nil != (key = [keyEnum nextObject]))
	{
		Log(@"%@:", key);
		Log(@"%@", [attributes objectForKey:key]);
	}
}

int main(int argc, char **argv)
{
	bool doNotPrint = false;
	NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];
	CMetadataImporter *importer = [[CMetadataImporter alloc] init];
	int argStartProcessingIndex = 1;

	if (argc == 1 || (argc > 1 && strcmp(argv[1], "-h") == 0))
	{
		printUsage(argv[0]);
		return 1;
	}
	
	if (argc > 1 && strcmp(argv[1], "-noprint") == 0)
	{
		doNotPrint = true;
		argStartProcessingIndex = 2;
	}
	
	int i;
	for (i = argStartProcessingIndex; i < argc; i++)
	{
		NSMutableDictionary *attribs = [[NSMutableDictionary alloc] init];
		NSString *path = [[NSString alloc] initWithCString:argv[i]];

		if (!doNotPrint)
		{
			NSLog(@"Processing '%@'", path);
		}
		
		BOOL success = [importer importFile:path contentType:@"" attributes:attribs];
		if (success != YES)
		{
			NSLog(@"Unable to process %s", argv[i]);
		}
		else
		{
			if (!doNotPrint)
			{
				printAttributes(attribs);
			}
		}
		[attribs release];
		[path release];
	} 

	[theAutoreleasePool release];
	
	return 0;
}
