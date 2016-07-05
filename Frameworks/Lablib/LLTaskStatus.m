//
//  TaskMode.m
//  Experiment
//
//  Created by John Maunsell on Tue Sep 16 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLTaskStatus.h"

@implementation LLTaskStatus

- (BOOL)dataFileOpen;
{
	return dataFileOpen;
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
}

- (void)setMode:(long)newMode {

	mode = newMode;
}

- (long)status;
{
	return ((mode & kLLTaskModeMask) | ((dataFileOpen) ? kLLFileOpenMask : 0));
}

@end
