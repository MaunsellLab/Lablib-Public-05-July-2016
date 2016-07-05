//
//  VTEndtrialState.h
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStateSystem.h"

@interface VTEndtrialState : LLState {

	NSTimeInterval	expireTime;
@private
	long			intervalCorrects[kIntervals][kMaxLevels];
	long			intervalTotals[kIntervals][kMaxLevels];
}

- (void)reset;

@end
