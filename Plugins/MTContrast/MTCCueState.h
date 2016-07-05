//
//  MTCCueState.h
//  MTContrast
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "MTCStateSystem.h"

@interface MTCCueState : NSObject {

	long			cueMS;
	NSTimeInterval	expireTime;
}

@end
