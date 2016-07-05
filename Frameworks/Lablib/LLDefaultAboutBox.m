//
//  LLDefaultAboutBox.m
//  Experiment
//
//  Created by John Maunsell on Wed May 05 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLDefaultAboutBox.h"

@implementation LLDefaultAboutBox
 
 - (id)init {
 
	if ((self =  [super initWithWindowNibName:@"LLDefaultAboutPanel"])) {
		[self window];
    }   
    return self;
}

- (NSString *)versionOfFramework:(NSString *)name {

	long index;
	NSArray *allFrameworks;
	NSString *frameworkName;
	NSString *version = nil;

	allFrameworks = [NSBundle allFrameworks];
	for (index = 0; index < [allFrameworks count]; index++) {
		frameworkName = [[allFrameworks objectAtIndex:index] 
								objectForInfoDictionaryKey:@"CFBundleExecutable"];
		if ([frameworkName isEqualToString:name]) {
			version = [[allFrameworks objectAtIndex:index] 
								objectForInfoDictionaryKey:@"CFBundleVersion"];
			break;
		}
	}
	return version;
}

- (void)windowDidLoad {

	NSString *string;
	
	string = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
	if (string == nil) {
		return;
	}
	[[self window] setTitle:[NSString stringWithFormat:@"About %@", string]];
	[executableField setStringValue:string];
	string = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	if (string != nil) {
		[versionField setStringValue:[NSString stringWithFormat:@"Version %@", string]];
	}
	string = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
	if (string != nil) {
		[copyrightField setStringValue:[NSString stringWithFormat:@"Copyright %@", string]];
	}
	
	string = [self versionOfFramework:@"Lablib"];
	[lablibField setStringValue:[NSString stringWithFormat:@"Lablib Version %@", string]];
	string = [self versionOfFramework:@"LablibITC18"];
	if (string != nil) {
		[lablibITC18Field setStringValue:[NSString stringWithFormat:@"LablibITC18 Version %@", string]];
	}
	else {
		[lablibITC18Field setStringValue:@""];
	}
}

@end
