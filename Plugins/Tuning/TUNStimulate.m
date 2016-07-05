//
//  TUNStimulate.m
//  Tuning
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNStimulate.h" 

@implementation TUNStimulate

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
	if ([[task defaults] boolForKey:TUNFixateKey] &&  ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![stimuli stimulusOn]) {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}


@end
