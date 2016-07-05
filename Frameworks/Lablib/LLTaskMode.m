//
//  TaskMode.m
//  Experiment
//
//  Created by John Maunsell on Tue Sep 16 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLTaskMode.h"

NSString *LLTaskModeChange = @"LLTaskModeChange";

@implementation LLTaskMode

- (BOOL)dataFileOpen;
{
	return dataFileOpen;
}

- (void)dealloc;
{
	[key release];
	[super dealloc];
}

- (id)init {
	
	if ([super init] != nil) {
		mode = kTaskIdle;
		dataFileOpen = NO;
	}
	return self;
}

- (BOOL)isEnding {
	
	return (mode >= kTaskEnding);
}

- (BOOL)isIdle {
	
	return (mode == kTaskIdle);
}

- (BOOL)isStopping {
	
	return (mode == kTaskStopping);
}

- (long) mode {

	return mode;
}

- (void)setDataFileOpen:(BOOL)state;
{
	dataFileOpen = state;
	[self setDefaults];
}

- (void)setDefaults;
{
	long value;
	
	if (key != nil) {
		NSLog(@"LLTaskMode setDefaults using key %@", key);
		NSLog(@"  current value is %ld", 
				(long)[[NSUserDefaults standardUserDefaults] integerForKey:key]);
		value = ((mode & kLLTaskModeMask) | 
					((dataFileOpen) ? kLLFileOpenMask : 0));
		NSLog(@"  setting to %ld", value);
		[[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
		NSLog(@"  done");
	}
}

- (void)setMode:(long)newMode {

	mode = newMode;
	[[NSNotificationCenter defaultCenter] postNotificationName:LLTaskModeChange object:[NSNumber numberWithLong:mode]];
	[self setDefaults];
}

@end
