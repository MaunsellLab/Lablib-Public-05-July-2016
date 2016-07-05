//
//  RFBlockedState.h
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFStateSystem.h"

@interface RFBlockedState : LLState {

	NSTimeInterval expireTime;
}

@end
