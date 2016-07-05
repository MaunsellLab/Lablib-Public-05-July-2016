//
//  VCANTooFastState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANTooFastState.h"
#import "VCANUtilities.h"
#import "UtilityFunctions.h"

@implementation VCANTooFastState

- (void)stateAction;
{	
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANTooFastMSKey]];
}

- (NSString *)name {

    return @"TooFast";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VCANFixateKey]) {		// no fixation requirement, give a reward
		eotCode = extendedEotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    
    if (![VCANUtilities inWindow:fixWindow]) { // started a saccade after target onset
        return [[task stateSystem] stateNamed:@"Saccade"];
        
    }
    if ([LLSystemUtil timeIsPast:expireTime]) {				// never reaponded: fail
        isNotTooFast = TRUE;
		return [[task stateSystem] stateNamed:@"React"];
	}
    return nil;
}

@end
