//
//  VTStateSystem.h
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VT.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

enum {kFirst, kSecond, kIntervals};

typedef struct {
	long	stimulusType;
	long	stimulusIndex;
	float   stimulusValue;
	long	stimulusInterval;
	float   respAziDeg;
	float   respEleDeg;
} TrialDesc;

extern long 			eotCode;			// End Of Trial code
extern LLEyeWindow		*fixWindow;
extern long				intervalIndex;
extern BOOL				leverIsDown;
extern LLEyeWindow		*respWindows[kIntervals];
extern TrialDesc		trial;

@interface VTStateSystem : LLStateSystem {

	long			stimType;
}


@end


