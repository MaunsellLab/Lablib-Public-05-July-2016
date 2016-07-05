//
//  VCANSaccadeState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANSaccadeState.h"
#import "VCANUtilities.h"

@implementation VCANSaccadeState

- (void)stateAction {

	[[task dataDoc] putEvent:@"saccade"];
	[digitalOut outputEvent:kSaccadeCode withData:0x0];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANSaccadeTimeMSKey]];
}

- (NSString *)name {

    return @"Saccade";
}

- (LLState *)nextState {

	long index;
	
	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    if ([VCANUtilities inWindow:respWindows[trial.attendLoc]])  {   // went to cued location
        if ([stimuli targetPresented] && isNotTooFast)  {			// correct response
            eotCode = extendedEotCode = kEOTCorrect;
        }
        else {										// false alarm
            eotCode = kEOTWrong;
            extendedEotCode = kEOTEarly;
        }
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
	for (index = 0; index < kStimLocs; index++) {
        if (index == trial.attendLoc) {
            continue;
        }
		if ([VCANUtilities inWindow:respWindows[index]])  {
            eotCode = kEOTWrong;
            extendedEotCode = ([stimuli isTargetActiveAtIndex:index]) ? kEOTDistractor : kEOTWrong;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if (![stimuli targetPresented]) {					// left fixation early, but got to no window
			eotCode = extendedEotCode = kEOTBroke;
		}
		else {												// target presented, no response
			eotCode = extendedEotCode = kEOTFailed;
		}
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}

@end
