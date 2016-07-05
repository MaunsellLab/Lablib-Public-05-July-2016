//
//  SCTooFastState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCTooFastState.h"
#import "UtilityFunctions.h"
#import "SCUtilities.h"

#define alpha		((trial.validTrial) ? 0.1 : 0.2)
#define kBeta		2.0

@implementation SCTooFastState

- (void)stateAction;
{
	float prob100;
	int tooFastMS;
	LLGabor *gabor;
	
	[[task dataDoc] putEvent:@"tooFast"];
	tooFastMS =  [[task defaults] integerForKey:SCTooFastMSKey];
	expireTime = [LLSystemUtil timeFromNow:tooFastMS];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 50.0 * exp(-exp(log(fabs(trial.orientationChangeDeg) / alpha) * kBeta));
	if ((rand() % 100) < prob100) {
		gabor = (trial.validTrial) ? [stimuli gaborWithIndex:trial.attendLoc] :
					[stimuli gaborWithIndex:(1 - trial.attendLoc)];
		[[task synthDataDevice] setEyeTargetOn:NSMakePoint([gabor azimuthDeg], [gabor elevationDeg])];
        NSLog(@"Synthetic Response");
	}
}

- (NSString *)name {

    return @"SCTooFast";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (![[task defaults] boolForKey:SCFixateKey]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	else {
		if (![SCUtilities inWindow:fixWindow]) {   // too fast reaction
			eotCode = kMyEOTBroke;
			return [[task stateSystem] stateNamed:@"SCSaccade"];;
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"SCReact"];
	}
    return nil;
}

@end
