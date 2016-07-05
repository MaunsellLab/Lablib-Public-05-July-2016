//
//  FTIntertrialState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTIntertrialState.h"

@implementation FTIntertrialState

- (void)stateAction {

	expireTime = [LLSystemUtil timeFromNow:
			[[NSUserDefaults standardUserDefaults] integerForKey:FTIntertrialMSKey]];
	eotCode = kEOTCorrect;			// Default eot code is correct
	
// update the fixtation and response windows

    [fixWindow setWidthAndHeightDeg:[[NSUserDefaults standardUserDefaults] floatForKey:FTFixWindowWidthDegKey]];
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskStopping) {
        eotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"Starttrial"];
    }
    return nil;
}

@end
