//
//  MTCStateSystem.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTC.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

extern short				attendLoc;
extern long					eotCode;			// End Of Trial code
extern LLEyeWindow			*fixWindow;
extern LLScheduleController *scheduler;
extern LLEyeWindow			*respWindows[kLocations];
extern TrialDesc			trial;

@interface MTCStateSystem : LLStateSystem {

	long			stimType;
}

@end

