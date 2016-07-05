//
//  LLStandardFileNames.m
//  Lablib
//
//  Created by John Maunsell on Sun Jun 01 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLStandardFileNames.h"
#import "LLSystemUtil.h"

#define kLLDefaultDataDir	@"/Users/Shared/Data"

NSString	*LLLastFileNameKey = @"LLLastFileName";
NSString	*LLDataFileExtention = @"dat";

@implementation LLStandardFileNames

+ (NSArray *)allowedFileTypes {
    
	return [NSArray arrayWithObject:LLDataFileExtention];
}

+ (BOOL)alphaIncrement:(const char *)cString characters:(long)length {

	long index;
	char workString[256];
	BOOL overflow = NO;
	
	if (length < 1) {
		return NO;
	}
	for (index = 0; index < length; index++) {
		workString[index] = tolower(cString[index]);
	}
	
	if (workString[length - 1] < 'z') {
		workString[length - 1]++;
	}
	else {
		workString[length - 1] = 'a';
		if (length > 1) {
			overflow = [LLStandardFileNames alphaIncrement:workString characters:length - 1];
		}
		else {
			overflow = YES;
		}
	}
	for (index = 0; index < length; index++) {
		((char *)cString)[index] = isupper(cString[index]) ? toupper(workString[index]) : workString[index];
	}
	return overflow;
}

+ (NSString *)defaultDirPath {

	NSString *path, *path1, *path2, *fileName;
	
// Make sure the Data folder exists

	path = kLLDefaultDataDir;
	if (![LLStandardFileNames findOrCreateDirectory:path]) {
		return nil;
	}
	
// Make sure that Data/X exists, where X is the first character of the file name

	fileName = [LLStandardFileNames defaultFileName];
	path1 = [path stringByAppendingPathComponent:[fileName substringToIndex:1]];
	if (![LLStandardFileNames findOrCreateDirectory:path1]) {
		return nil;
	}

// Make sure that Data/X/YZ exists, where YZ are the second and third characters of the file name

	path2 = [path1 stringByAppendingPathComponent:[fileName substringWithRange:NSMakeRange(1,2)]];
	if (![LLStandardFileNames findOrCreateDirectory:path2]) {
		return nil;
	}
	return path2;
}

+ (NSString *)defaultFileExtension {

	return LLDataFileExtention;
}

+ (NSString *)defaultFileName {

	NSString *lastName, *newName;
	const char *string;
	
	lastName = [[[NSUserDefaults standardUserDefaults] stringForKey:LLLastFileNameKey]
					stringByDeletingPathExtension];
	if (![LLStandardFileNames standardNameFormat:lastName]) {
		return(lastName);
	}
	string = [lastName cStringUsingEncoding:NSUTF8StringEncoding];
	if ([LLStandardFileNames numIncrement:&string[5] characters:2]) {
		[LLStandardFileNames alphaIncrement:string characters:5];
	}
	newName = [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
	return [newName stringByAppendingPathExtension:LLDataFileExtention];
}	

+ (BOOL)findOrCreateDirectory:(NSString *)path {

	BOOL isDirectory;
	NSFileManager *manager = [NSFileManager defaultManager];
	
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) {
		if (![manager createDirectoryAtPath:kLLDefaultDataDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className]
                    informativeText:[NSString stringWithFormat:@"Unable to create directory \"%@\".", path]];
//			NSRunAlertPanel(@"LLStandardFileNames",
//						@"Unable to create directory \"%@\".", @"OK", 
//						nil, nil, path);
			return NO;
		}
	}
	else if (!isDirectory) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
             @"Cannot create data directory  \"%@\" because file exist with that name.", path]];
//		NSRunAlertPanel(@"LLStandardFileNames",
//			@"Cannot create data directory  \"%@\" because file exist with that name.", 
//			@"OK", nil, nil, path);
		return NO;
	}
	return YES;
}

+ (BOOL)numIncrement:(const char *)cString characters:(long)length {

	BOOL overflow = NO;
	
	if (length < 1) {
		return NO;
	}
	if (cString[length - 1] < '9') {
		((char *)cString)[length - 1]++;
	}
	else {
		((char *)cString)[length - 1] = '0';
		if (length > 1) {
			overflow = [LLStandardFileNames numIncrement:cString characters:length - 1];
		}
		else {
			overflow = YES;
		}
	}
	return overflow;
}

+ (BOOL)standardNameFormat:(NSString *)fileName {

	long index;
	const char *cString;
	
	if ([fileName length] != 7) {
		return NO;
	}
	cString = [fileName cStringUsingEncoding:NSUTF8StringEncoding];
	if (!isdigit(cString[5]) || !isdigit(cString[6])) {
		return NO;
	}
	for (index = 0; index < 5; index++) {
		if (!isalpha(cString[index])) {
			return NO;
		}
	}
	return YES;
}

@end
