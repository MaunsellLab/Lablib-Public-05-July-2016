//
//  LLTaskModeTransformer.h
//  Lablib
//
//  Created by John Maunsell on 12/28/04.
//  Copyright 2004. All rights reserved.
//

// An LLTaskModeTransformer can be set to perform several different
// transformations  on the value stored by LLTaskMode.

enum  {kLLTaskModeIdle,				// Return BOOL for task mode is idle
		kLLTaskModeIdleAndNoFile,	// Return BOOL for idle and no data file open
		kLLTaskModeNoFile};			// Return BOOL for no data file open
		
@interface LLTaskModeTransformer:NSValueTransformer {

	long type;
}

- (void)setTransformerType:(long)newType;

@end
