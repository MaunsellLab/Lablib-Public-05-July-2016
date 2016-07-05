//
//  LLTaskMode.h
//  Experiment
//
//  Created by John Maunsell on Tue Sep 16 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLStandardDataEvents.h"

extern NSString *LLTaskModeChange;

@interface LLTaskMode : NSObject {

	BOOL		dataFileOpen;
	NSString	*key;
	long		mode;
}

- (BOOL)dataFileOpen;
- (BOOL)isEnding;
- (BOOL)isIdle;
- (BOOL)isStopping;
- (long)mode;
- (void)setDataFileOpen:(BOOL)state;
- (void)setDefaults;
- (void)setMode:(long)newMode;

@end
