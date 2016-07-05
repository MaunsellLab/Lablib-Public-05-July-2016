//
//  TUNIntertrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNIntertrialState.h"
#import "UtilityFunctions.h"

@implementation TUNIntertrialState

- (void)stateAction;
{
	long index;
	BOOL done;

// Increment the block counter and count the number of trials done in the last block;

	blockStatus.blockLimit = [[task defaults] integerForKey:TUNBlockLimitKey];
	done = NO;
	do {
		for (index = blockStatus.stimDoneThisBlock = 0; index < testParams.steps; index++) {
			if (stimDone[index] > blockStatus.blocksDone) {
				blockStatus.stimDoneThisBlock++;
			}
		}
		if (blockStatus.stimDoneThisBlock == testParams.steps) {
			blockStatus.blocksDone++;
		}
		else {
			done = YES;
		}
	} while (!done);
	
	if (blockStatus.blocksDone >= blockStatus.blockLimit) {		// all blocks have been done
		[task setMode:kTaskIdle];
		return;
	}

	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:TUNIntertrialMSKey]];
	eotCode = kEOTCorrect;							// default eot code is correct
	trial.stimPerTrial = [[task defaults] integerForKey:TUNStimPerTrialKey];
	[stimuli makeStimList:&trial];
	[stimuli dumpStimList];
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskIdle) {
        eotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"StartTrial"];
    }
    return nil;
}

@end
