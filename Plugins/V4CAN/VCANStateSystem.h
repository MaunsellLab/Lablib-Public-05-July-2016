//
//  VCANStateSystem.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCAN.h"
#import "Quest.h"
#import "VCANDigitalOut.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

extern long					eotCode;					// End Of Trial code
extern long					extendedEotCode;			// End Of Trial code
extern LLEyeWindow			*fixWindow;
extern LLScheduleController *scheduler;
extern Quest				*q[kNumStates];
extern LLEyeWindow			*respWindows[kStimLocs];
extern float                staircaseContrastPC[kNumStates];
extern long                 staircaseCounts[kNumStates];
extern TrialDesc			trial;
extern BOOL                 isNotTooFast;

@interface VCANStateSystem : LLStateSystem {

	BOOL	questOpen;
	long	stimType;
}

- (void)doStaircaseReset;

@end

