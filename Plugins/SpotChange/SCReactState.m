//
//  SCReactState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCReactState.h"
#import "UtilityFunctions.h"
#import "SCUtilities.h"

#define kAlpha		2.5
#define kBeta		2.0

@implementation SCReactState

- (void)stateAction;
{

	[[task dataDoc] putEvent:@"react"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCRespTimeMSKey] -
                    [[task defaults] integerForKey:SCTooFastMSKey]];
}

- (NSString *)name {

    return @"SCReact";
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
		if (![SCUtilities inWindow:fixWindow]) {   // started a saccade
//			[[task dataDoc] putEvent:@"saccadeLaunched"]; 
			return [[task stateSystem] stateNamed:@"SCSaccade"];
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTMissed;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}

@end
