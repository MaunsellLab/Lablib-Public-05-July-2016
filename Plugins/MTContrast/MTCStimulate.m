//
//  MTCStimulate.m
//  MTContrast
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCStimulate.h" 

@implementation MTCStimulate

- (void)stateAction;
{
	[stimuli startStimList];
}

- (NSString *)name {

    return @"Stimulate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:MTCFixateKey] &&  ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![stimuli stimulusOn]) {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([stimuli targetPresented]) {
		return [[task stateSystem] stateNamed:@"React"];
	}
    return nil;
}


@end
