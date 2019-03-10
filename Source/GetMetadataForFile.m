//  GetMetadataForFile.m
//
//  Lisp Metadata Importer
//
//  Created by John Wiseman on 9/1/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import <Foundation/Foundation.h>

#import "CMetadataImporter.h"

Boolean GetMetadataForFile(void* thisInterface, NSMutableDictionary *attributes, NSString *contentTypeUTI, NSString *pathToFile)
{
	BOOL theResult = NO;
	NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		CMetadataImporter *theImporter = [[[CMetadataImporter alloc] init] autorelease];
		theResult = [theImporter importFile:pathToFile contentType:contentTypeUTI attributes:attributes];
	}
	@catch (NSException *localException)
	{
		NSLog(@"Exception caught during import operation: %@", localException);
	}
	@finally
	{
	}
	
	[theAutoreleasePool release];
	
	return(theResult);;
}
