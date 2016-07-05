//
//  VCANCueState.h
//  V4CAN
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "VCANStateSystem.h"

@interface VCANCueState : LLState {

	long			cueMS;
	NSTimeInterval	expireTime;
}

@end
