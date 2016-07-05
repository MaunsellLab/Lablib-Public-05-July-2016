//
//  FTFixonState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTFixonState.h"
#import "FTUtilities.h"

@implementation FTFixonState

- (void)stateAction;
{
    [stimuli drawFixSpot];
	[[task dataDoc] putEvent:@"fixOn"];
    [[task synthDataDevice] doLeverDown];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:
			[[NSUserDefaults standardUserDefaults] integerForKey:FTAcquireMSKey]];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FTDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"Fixon";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[NSUserDefaults standardUserDefaults] boolForKey:FTDoFixateKey]) {
		return [[task stateSystem] stateNamed:@"Fixate"];
    }
	else if ([FTUtilities inWindow:fixWindow])  {
		return [[task stateSystem] stateNamed:@"Fixate"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		return nil;
    }
}

@end
