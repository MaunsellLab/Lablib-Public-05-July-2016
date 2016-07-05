//
//  RFStateSystem.h
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RF.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

typedef struct {
	long	stimulusType;
} TrialDesc;

extern long 			eotCode;			// End Of Trial code
extern LLEyeWindow		*fixWindow;
extern long				intervalIndex;
extern TrialDesc		trial;

@interface RFStateSystem : LLStateSystem {
}

@end


