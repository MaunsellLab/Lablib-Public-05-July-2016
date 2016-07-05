//
//  SCStateSystem.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SC.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

//extern short				attendLoc;
extern long					eotCode;			// End Of Trial code
extern LLEyeWindow			*fixWindow;
extern LLScheduleController *scheduler;
extern LLEyeWindow			*respWindow;
extern TrialDesc			trial;
extern LLEyeWindow			*wrongWindow;

@interface SCStateSystem : LLStateSystem {

}

@end

