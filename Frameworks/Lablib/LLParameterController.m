//
//  LLParameterController.m
//  Lablib
//
//  Created by John Maunsell on Sun Aug 01 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLParameterController.h"
#import "LLSystemUtil.h"

@implementation LLParameterController

- (void)dealloc {

	[parameters release];
	[super dealloc];
}

- (id)init {

	if ((self = [super init]) != nil) {
		parameters = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)loadViewAndSubviews:(NSView *)view {

	NSLog(@"loadViewAndSubviews for %@", view);
}

- (void)registerParameters:(LLParameter *)paramList {

	NSNumber *value;
	NSData *data;

	while (paramList != NULL) {
		if ([parameters objectForKey:paramList->name] != nil) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                        @"Attempt to register parameter named %@ more than once", paramList->name]];
//			NSRunAlertPanel(@"LLParameters",
//						@"Attempt to register parameter named %@ more than once",
//						@"OK", nil, nil, paramList->name);
			exit(1);
		}
		value = nil;
		data = nil;
		switch (paramList->type) {
		case kBoolean:
		case kChar:
		case kSignedChar:
		case kUnsignedChar:
			value = [NSNumber numberWithBool:(paramList->defaultValue).boolParam];
			break;
		case kInt:
		case kUnsignedInt:
		case kLong:
		case kUnsignedLong:
			value = [NSNumber numberWithInt:(paramList->defaultValue).longParam];
			break;
		case kFloat:
			value = [NSNumber numberWithFloat:(paramList->defaultValue).floatParam];
			break;
		case kShort:
		case kUnsignedShort:
		case kDouble:
		case kLongDouble:
		case kLongLong:
		case kUnsignedLongLong:
			value = nil;
			break;
		case kPtr:
			data = [NSData dataWithBytes:(paramList->defaultValue).ptr
													length:paramList->lengthBytes];
		}
		if (value != nil) {
			[parameters setObject:value forKey:paramList->name];
		}
		if (data != nil) {
			[parameters setObject:data forKey:paramList->name];
		}
		paramList++;
	}
	[[NSUserDefaults standardUserDefaults] registerDefaults:parameters];
}

@end
