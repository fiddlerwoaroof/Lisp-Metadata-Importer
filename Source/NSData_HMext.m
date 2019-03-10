//  NSData_HMext.m
//
//  Created by John Wiseman on 9/6/05.
//  Copyright 2005 John Wiseman.
//
//  Licensed under the MIT license--see the accompanying LICENSE.txt
//  file.


#import "NSData_HMExt.h"
#import "DebugLog.h"


// Reads up to maxLen bytes from a file into a buffer.  The
// buffer is allocated and returned in buf, while the number of
// bytes read is returned in len.
//
// More or less taken from GnuStep's implementation of NSData.

static BOOL readContentsOfFile(NSString* path, void** buf, unsigned int maxLen, unsigned int* len, NSZone* zone)
{
	const char	*thePath = 0;
	FILE		*theFile = 0;
	void		*tmp = 0;
	int			c;
	long		fileLength;
	
	thePath = [path fileSystemRepresentation];
	if (thePath == 0)
    {
		//      NSWarnFLog(@"Open (%@) attempt failed - bad path", path);
		return NO;
    }
	
	theFile = fopen(thePath, "rb");
	
	if (theFile == 0)		/* We failed to open the file. */
    {
		//      NSWarnFLog(@"Open (%@) attempt failed - %s", path,
		//      GSLastErrorStr(errno));
		goto failure;
    }
	
	/*
	 *	Seek to the end of the file.
	 */
	c = fseek(theFile, 0L, SEEK_END);
	if (c != 0)
    {
		//      NSWarnFLog(@"Seek to end of file (%@) failed - %s", path,
		//      GSLastErrorStr(errno));
		goto failure;
    }
	
	/*
	 *	Determine the length of the file (having seeked to the end of the
										  *	file) by calling ftell().
	 */
	fileLength = ftell(theFile);
	if (fileLength == -1)
    {
		//      NSWarnFLog(@"Ftell on %@ failed - %s", path,
		//      GSLastErrorStr(errno));
		goto failure;
    }
	
	/*
	 *	Rewind the file pointer to the beginning, preparing to read in
	 *	the file.
	 */
	c = fseek(theFile, 0L, SEEK_SET);
	if (c != 0)
    {
		//      NSWarnFLog(@"Fseek to start of file (%@) failed - %s", path,
		//      GSLastErrorStr(errno));
		goto failure;
    }
	
	if (fileLength == 0)
    {
		unsigned char	buf[BUFSIZ];
		unsigned bytesToRead = maxLen;
		/*
		 * Special case ... a file of length zero may be a named pipe or some
		 * file in the /proc filesystem, which will return us data if we read
		 * from it ... so we try reading as much as we can, up to the specified
		 * limit.
		 */
		while ((c = fread(buf, 1, (bytesToRead < BUFSIZ) ? bytesToRead : BUFSIZ, theFile)) != 0)
		{
			if (tmp == 0)
			{
				tmp = NSZoneMalloc(zone, c);
			}
			else
			{
				tmp = NSZoneRealloc(zone, tmp, fileLength + c);
			}
			if (tmp == 0)
			{
				//	      NSLog(@"Malloc failed for file (%@) of length %d - %s", path,
				//		fileLength + c, GSLastErrorStr(errno));
				goto failure;
			}
			memcpy(tmp + fileLength, buf, c);
			fileLength += c;
			bytesToRead -= c;
		}
		if (fileLength == maxLen)
		{
			DebugLog(DEBUG_LEVEL_DEBUG, @"Truncated indexing of %s to %d bytes", thePath, maxLen);
		}
    }
	else
    {
		if (fileLength > maxLen)
		{
			fileLength = maxLen;
			DebugLog(DEBUG_LEVEL_DEBUG, @"Truncated indexing of %s to %d bytes", thePath, maxLen);
		}
		tmp = NSZoneMalloc(zone, fileLength);
		if (tmp == 0)
		{
			//	  NSLog(@"Malloc failed for file (%@) of length %d - %s", path,
			//	  fileLength, GSLastErrorStr(errno));
			goto failure;
		}
	    
		c = fread(tmp, 1, fileLength, theFile);
		if (c != (int)fileLength)
		{
			//	  NSWarnFLog(@"read of file (%@) contents failed - %s", path,
			//	  GSLastErrorStr(errno));
			goto failure;
		}
    }
	
	*buf = tmp;
	*len = fileLength;
	fclose(theFile);
	return YES;
	
	/*
	 *	Just in case the failure action needs to be changed.
	 */
failure:
		if (tmp != 0)
		{
			NSZoneFree(zone, tmp);
		}
	if (theFile != 0)
    {
		fclose(theFile);
    }
	return NO;
}

@implementation NSData (NSData_Extensions)


/**
 * Returns a data object encapsulating the contents of the specified file
 * (but only up to the first theMaxSize bytes of the file).
 * Invokes -initWithContentsOfFile:
 *
 * Based on GnuStep's -[NSData dataWithContentsOfFile].
 */
+ (id) dataWithContentsOfFile: (NSString*)path maxSize:(int)theMaxSize error:(NSError**)error
{
	NSData	*d;
	
	d = [NSData allocWithZone: NSDefaultMallocZone()];
	d = [d initWithContentsOfFile: path maxSize:theMaxSize error:error];
	return [d autorelease];
}


/**
 * Initializes the receiver with up to theMaxSize bytes of the specified file.
 * Returns the resulting object.
 * Returns nil if the file does not exist or can not be read for some reason,
 * in which case error information will (probably) be returned as well.
 *
 * Based on GnuStep's -[NSData initWithContentsOfFile].
 */
- (id) initWithContentsOfFile: (NSString*)path maxSize:(int)theMaxSize error:(NSError**)error
{
	void		*fileBytes = NULL;
	unsigned	fileLength = 0;
	NSZone	*zone;
	
	zone = NSDefaultMallocZone();
	if (readContentsOfFile(path, &fileBytes, theMaxSize, &fileLength, zone) == NO)
    {
		if (error)
		{
			NSNumber *errorCode = [NSNumber numberWithInt:errno];
			NSString *errorDescription = [NSString stringWithCString:strerror(errno)];
			NSString* errorPath = path;
			NSMutableDictionary *errorAttribs = [NSMutableDictionary dictionaryWithCapacity:2];
			[errorAttribs setObject:errorCode forKey:@"Errno"];
			[errorAttribs setObject:errorDescription forKey:@"Description"];
			[errorAttribs setObject:errorPath forKey:@"Path"];
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:errorAttribs];
		}
		[self dealloc];
		return nil;
    }
	else
    {
		self = [self initWithBytesNoCopy:fileBytes length:fileLength freeWhenDone:YES];
    }
	return self;
}

@end
