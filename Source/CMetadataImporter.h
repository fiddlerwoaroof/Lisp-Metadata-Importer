//  CMetadataImporter.h
//
//  Lisp Metadata Importer
//
//  Created by John Wiseman on 9/1/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.

#import <Cocoa/Cocoa.h>

#import "AGRegex.h"

@interface CMetadataImporter : NSObject {

}

// "Public" methods.

- (BOOL)importFile:(NSString *)inPathToFile contentType:(NSString *)inContentType attributes:(NSMutableDictionary *)inAttributes;


// "Private" methods.

- (void)initStaticData;
- (BOOL)addMatchesTo:(NSMutableDictionary *)attributes fromLine:(NSString *)line usingRE:(AGRegex *)regex forKey:(NSString *)key;
- (NSString*)readContentsOfFile:(NSString*)path error:(NSError**)theError;

@end
