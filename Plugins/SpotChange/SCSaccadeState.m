//
//  SCSaccadeState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCSaccadeState.h"
#import "SCDigitalOut.h"
#import "SCUtilities.h"

@implementation SCSaccadeState

- (void)stateAction {

	[[task dataDoc] putEvent:@"saccade"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCSaccadeTimeMSKey]];
	[digitalOut outputEvent:kSaccadeCode withData:kSaccadeCode];
}

- (NSString *)name {

    return @"SCSaccade";
}

- (LLState *)nextState;
{	
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (eotCode == kMyEOTBroke) {				// got here by leaving fixWindow early (from stimulate)
		if ([SCUtilities inWindow:respWindow])  {
            eotCode = (trial.validTrial) ? kMyEOTEarlyToValid : kMyEOTEarlyToInvalid;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([SCUtilities inWindow:wrongWindow])  {
            eotCode = (trial.validTrial) ? kMyEOTEarlyToInvalid: kMyEOTEarlyToValid;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([LLSystemUtil timeIsPast:expireTime]) {
			eotCode = kMyEOTBroke;
			brokeDuringStim = YES;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
	else {
		if ([SCUtilities inWindow:respWindow])  {
			eotCode = kMyEOTCorrect;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([SCUtilities inWindow:wrongWindow])  {
            eotCode = (trial.validTrial) ? kMyEOTEarlyToInvalid: kMyEOTEarlyToValid;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([LLSystemUtil timeIsPast:expireTime]) {
			eotCode = kMyEOTMissed;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
    return nil;
}

@end
