//
//  LLTaskStatusTransformer.h
//  Lablib
//
//  Created by John Maunsell on 12/28/04.
//  Copyright 2004. All rights reserved.
//

// An LLTaskStatusTransformer can be set to perform several different
// transformations  on the value stored by LLTaskStatus.

enum  {kLLTaskStatusIdle,				// Return BOOL for task mode is idle
		kLLTaskStatusIdleAndNoFile,		// Return BOOL for idle and no data file open
		kLLTaskStatusNoFile};			// Return BOOL for no data file open
		
@interface LLTaskStatusTransformer:NSValueTransformer {

	long type;
}

- (void)setTransformerType:(long)newType;

@end
