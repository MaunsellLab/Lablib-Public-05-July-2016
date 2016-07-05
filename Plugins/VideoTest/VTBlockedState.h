//
//  VTBlockedState.h
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStateSystem.h"

@interface VTBlockedState : LLState {

	NSTimeInterval	expireTime;
}

@end
