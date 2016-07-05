//
//  VTTargetsOnState.m
//  Experiment
//
//  Created by John Maunsell on Fri Feb 13 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "VTTargetsOnState.h"
#import "UtilityFunctions.h"


@implementation VTTargetsOnState

- (void)stateAction {

	long nontargetContrast = [[task defaults] integerForKey:VTNontargetContrastPCKey];

	[[task dataDoc] putEvent:@"targetsOn"];
	[stimuli setTargets:YES contrast0:(trial.stimulusInterval == 0) ? 100 : nontargetContrast
					contrast1:(trial.stimulusInterval == 1) ? 100 : nontargetContrast];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTTooFastMSKey]];
}

- (NSString *)name {

    return @"TargetsOn";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VTFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"React"];
	}
	return nil;
}

@end
