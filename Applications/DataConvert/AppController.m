//
//  AppController.m
//  DataConvert
//
//  This class exists mainly to set up the overhead for the application

//  Created by John Maunsell on Sun Jun 16 2002.
//  Copyright (c) 2005. All rights reserved.
//

#import "AppController.h"
#import "DataFile.h"

NSString *DCDataFormatKey = @"DCDataFormat";
NSString *DCOverwriteMatlabFilesKey = @"DCOverwriteMatlabFiles";
NSString *DCShowAddressKey = @"DCShowAddress";
NSString *DCShowDataKey = @"DCShowData";
NSString *DCShowTimeKey = @"DCShowTime";
NSString *DCShowTimeOfDayKey = @"DCShowTimeOfDay";

@implementation AppController

+ (void)initialize;
{
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	
// Load the default values for the user defaults.  These are the values that are used the first time
// the program is run.  Subsequent changes to values are preserved and used.  The default values are
// kept in UserDefaults.plist, which is in the application folder.  It is easier to edit this file with the 
// XML Editor rather than the XCode editor (although that is possible for quick changes.

	userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSDocumentController sharedDocumentController] openDocument:nil];
}

// The following delegate method is called when a file or files are dragged and dropped on the application
// icon.  In this case we run in the background and do conversions to Matlab files

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	NSLog(@"AppController: openFiles:%@", filenames);
}

// Stop the application from opening an empty window

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
{
    return NO;
}

// Convert all open documents to Matlab format

- (IBAction)convertFilesToMatlab:(id)sender;
{
	NSEnumerator *enumerator;
	NSDocument *document;
	NSURL *fileURL;
	NSString *path;
	NSError *outError;
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	
	outError = [[NSError alloc] init];
	enumerator = [documents objectEnumerator];
	while ((document = [enumerator nextObject])) {
		if (![[document class] isSubclassOfClass:[DataFile class]]) {
			continue;
		}
		fileURL = [document fileURL];
		if (![fileURL isFileURL]) {
			continue;
		}
		path = [[[fileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"m"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path] &&
					![[NSUserDefaults standardUserDefaults] boolForKey:DCOverwriteMatlabFilesKey]) {
			continue;
		}
		fileURL = [NSURL fileURLWithPath:path];
        //		NSLog(@"Path %@ absoluteString %@", [fileURL path], [fileURL absoluteString]);
		[document writeToURL:[fileURL absoluteURL] ofType:LLMatlabText error:&outError];
	}
	[outError release];
}

- (id)init;
{
	if ((self = [super init])) {
		[self setDelegate:self];
	}
	return self;
}

@end
