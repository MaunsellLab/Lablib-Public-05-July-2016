//
//  VICueState.h
//  VICAN
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "VIStateSystem.h"

@interface VICueState : LLState {

	long			cueMS;
	NSTimeInterval	expireTime;
}

@end
