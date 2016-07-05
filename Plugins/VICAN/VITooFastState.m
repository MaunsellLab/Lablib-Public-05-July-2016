//
//  VITooFastState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VITooFastState.h"
#import "VIUtilities.h"
#import "UtilityFunctions.h"

@implementation VITooFastState

- (void)stateAction;
{	
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VITooFastMSKey]];
}

- (NSString *)name {

    return @"TooFast";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VIFixateKey]) {		// no fixation requirement, give a reward
		eotCode = extendedEotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    
    if (![VIUtilities inWindow:fixWindow]) { // started a saccade after target onset
        return [[task stateSystem] stateNamed:@"Saccade"];
        
    }
    if ([LLSystemUtil timeIsPast:expireTime]) {				// never reaponded: fail
        isNotTooFast = TRUE;
		return [[task stateSystem] stateNamed:@"React"];
	}
    return nil;
}

@end
