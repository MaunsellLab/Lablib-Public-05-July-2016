//
//  FTStateSystem.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTStateSystem.h"

#import "FTBlockedState.h"
#import "FTEndtrialState.h"
#import "FTFixateState.h"
#import "FTFixonState.h"
#import "FTIdleState.h"
#import "FTIntertrialState.h"
#import "FTStartState.h"
#import "FTStarttrialState.h"
#import "FTStopState.h" 

long 					eotCode;			// End Of Trial code
BOOL 					fixated;
LLEyeWindow				*fixWindow;
FTStateSystem				*stateSystem;
TrialDesc				trial;

@implementation FTStateSystem

- (void)dealloc;
{
    [fixWindow release];
    [super dealloc];
}

- (id)init {

    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[FTBlockedState alloc] init] autorelease]];
		[self addState:[[[FTEndtrialState alloc] init] autorelease]];
		[self addState:[[[FTFixateState alloc] init] autorelease]];
		[self addState:[[[FTFixonState alloc] init] autorelease]];
		[self addState:[[[FTIdleState alloc] init] autorelease]];
		[self addState:[[[FTIntertrialState alloc] init] autorelease]];
		[self addState:[[[FTStartState alloc] init] autorelease]];
		[self addState:[[[FTStarttrialState alloc] init] autorelease]];
		[self addState:[[[FTStopState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Start"] andStopState:[self stateNamed:@"Stop"]];
//		[controller setLogging:YES];
			
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[NSUserDefaults standardUserDefaults] 
			floatForKey:FTFixWindowWidthDegKey]];

// Initialize the trialBlock that keeps track of trials and blocks

    }
    return self;
}

- (BOOL) running {

    return [controller running];
}

- (BOOL)startWithCheckIntervalMS:(double)checkMS {			// start the system running

    return [controller startWithCheckIntervalMS:checkMS];
}

- (void) stop {										// stop the system

    [controller stop];
}

// Methods related to data events follow:

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

// The indirect way of calling reset in the end trial state is used to avoid a circularity
// in header files refrences.

//	[endtrial performSelector:@selector(reset)];
}

@end
