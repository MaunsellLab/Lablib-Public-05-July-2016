//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCAN.h"
#import "UtilityFunctions.h"

#define kPrefRate			100.0
#define kSpontRate			15.0
#define kNullRate			20.0
#define kBeta

void announceEvents(void) {

    long lValue;
    float floatValue;
	char *idString = "V4CAN Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"gabor" withData:(Ptr)[[stimuli gabor] gaborData]];
    floatValue = [[task defaults] floatForKey:VCANEccentricityDegKey];
	[[task dataDoc] putEvent:@"eccentricityDeg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VCANAngleRF0DegKey];
	[[task dataDoc] putEvent:@"polarAngleRF0Deg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VCANAngleRF1DegKey];
	[[task dataDoc] putEvent:@"polarAngleRF1Deg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VCANAngleRFOutDegKey];
	[[task dataDoc] putEvent:@"polarAngleRFOutDeg" withData:(Ptr)&floatValue];

    lValue = [[task defaults] integerForKey:VCANStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VCANPrecueMSKey];
	[[task dataDoc] putEvent:@"precueMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VCANPreStimMSKey];
	[[task dataDoc] putEvent:@"preStimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VCANInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VCANStimLeadMSKey];
	[[task dataDoc] putEvent:@"stimLeadMS" withData:(Ptr)&lValue];    
    lValue = [[task defaults] integerForKey:VCANRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VCANTooFastMSKey];
	[[task dataDoc] putEvent:@"tooFastTimeMS" withData:(Ptr)&lValue];
	lValue = [[task defaults] integerForKey:VCANStimRepsPerBlockKey];
	[[task dataDoc] putEvent:@"stimRepsPerBlock" withData:(void *)&lValue];
	lValue = [[task defaults] integerForKey:VCANMaxTargetMSKey];
	[[task dataDoc] putEvent:@"maxTargetMS" withData:(void *)&lValue];
}

NSPoint azimuthAndElevationForStimLoc(StimLoc loc, TaskState state) {
    
    float polarAngleDeg, eccentricityDeg;
    NSPoint aziEle;
    
    eccentricityDeg = [[task defaults] floatForKey:VCANEccentricityDegKey];
    //    polarAngleDeg = [[task defaults] floatForKey:VCANAngleRF0DegKey];
    switch (loc) {
        case kGabor0:
        default:
            polarAngleDeg = [[task defaults] floatForKey:VCANAngleRF0DegKey];
            break;
        case kGabor1:
            if (state <= kInInAttFar1) {         // In/In configuration
                polarAngleDeg = [[task defaults] floatForKey:VCANAngleRF1DegKey];
            }
            else {                                  // In/Out configuration
                polarAngleDeg = [[task defaults] floatForKey:VCANAngleRFOutDegKey];
            }
            break;
        case kGaborFar0:
            polarAngleDeg = [[task defaults] floatForKey:VCANAngleRF0DegKey] + 180.0;
            break;
        case kGaborFar1:
            if (state <= kInInAttFar1) {         // In/In configuration
                polarAngleDeg = [[task defaults] floatForKey:VCANAngleRF1DegKey] + 180.0;
            }
            else {                                  // In/Out configuration
                polarAngleDeg = [[task defaults] floatForKey:VCANAngleRFOutDegKey] + 180.0;
            }
            break;
    }
    aziEle.x = eccentricityDeg * cos(polarAngleDeg / kDegPerRadian);
    aziEle.y = eccentricityDeg * sin(polarAngleDeg / kDegPerRadian);
    return aziEle;
}

void requestReset(void) {

    if ([task mode] == kTaskIdle) {
        reset();
    }
    else {
        resetFlag = YES;
    }
}

void reset(void) {

    long resetType = 0;
    
	[[task dataDoc] putEvent:@"reset" withData:&resetType];
}

float spikeRateSpontaneous(void) {

	return kSpontRate;
}

float spikeRateFromStimDesc(StimDesc *pSD) {

	long index;
    float r, d, rate;
    float driveRates[] = {kSpontRate, kNullRate, kPrefRate};
    float beta = 1.25;
	
    if (pSD->attendState / (kNumStates / 2) == 0) {                 // In/In configuration
        if ((pSD->stimTypes[0] == kNoStim) && (pSD->stimTypes[1] == kNoStim)) {
            rate = (pSD->attendLoc > kStimLocs / 2) ? kSpontRate : kSpontRate * beta;
        }
        else if (pSD->stimTypes[0] == kNoStim) {
            rate = driveRates[pSD->stimTypes[1]] * ((pSD->attendLoc == 1) ? beta : 1.0);
        }
        else if (pSD->stimTypes[1] == kNoStim) {
            rate = driveRates[pSD->stimTypes[0]] * ((pSD->attendLoc == 0) ? beta : 1.0);
        }
        else {
            for (index = r = d = 0; index < 2; index++) {
                r += driveRates[pSD->stimTypes[index]] * ((pSD->attendLoc == index) ? beta : 1.0);
                d += (pSD->attendLoc == index) ? beta : 1.0;
            }
            rate = r / d;
        }
    }
    else {                                                          // In/Out configuration
        rate = driveRates[pSD->stimTypes[0]] * ((pSD->attendLoc == 0) ?  beta : 1);
    }
    return rate;
}

void updateBlockStatus(void) {

	long stim, state, offset, blocksDoneThisSet;

    blockStatus.stimPerState = kStimPerState;
    
    //Give extra repetitions for the most difficult attentional states:
    if (trial.attendState < 2 || trial.attendState == 4 || trial.attendState == 5) {
        blockStatus.presPerState = blockStatus.stimPerState * ([[task defaults] integerForKey:VCANStimRepsPerBlockKey] + [[task defaults]integerForKey:VCANExtraDifficultStimRepsKey]);
    }
    else {
        blockStatus.presPerState = blockStatus.stimPerState * [[task defaults] integerForKey:VCANStimRepsPerBlockKey];
    }
	blockStatus.presDoneThisState = -(blockStatus.blocksDone * blockStatus.presPerState);
	blockStatus.statesPerBlock = kNumStates;
	blockStatus.blockLimit = [[task defaults] integerForKey:VCANBlockLimitKey];
	for (stim = 0; stim < kStimPerState; stim++) {
        blockStatus.presDoneThisState += stimDone[blockStatus.attendState][stim];
	}
	
// If we've finished the presentations for this state, we need to pick a new state
	
	if (blockStatus.presDoneThisState >= blockStatus.presPerState) {
		blockStatus.doneStates[blockStatus.attendState]++;
		blockStatus.instructsDone = 0; 
		blockStatus.presDoneThisState = 0;
		
// If we've finished all states for this block, then we need to advance to the next block and 
// pick a random state
		
		if (++blockStatus.statesDoneThisBlock >= blockStatus.statesPerBlock) {
			blockStatus.blocksDone++;
			blockStatus.statesDoneThisBlock = 0;
			for (state = 0; state < kNumStates; state++) {
				blockStatus.doneStates[state] = 0;
			}
            if (blockStatus.attendState < kNumStates / 2) {          // switch to the other condition at block end
                blockStatus.attendState = (rand() % (kNumStates / 2)) + (kNumStates / 2);
                NSLog(@"Set attendState to %ld", blockStatus.attendState);
            }
            else {
                blockStatus.attendState = (rand() % (kNumStates / 2));
                NSLog(@"Set attendState to %ld", blockStatus.attendState);
           }
		}
		else {
			if (blockStatus.attendState < kNumStates / 2) {
                for (state = blocksDoneThisSet = 0; state < kNumStates / 2; state++) {
                    blocksDoneThisSet += blockStatus.doneStates[state];
                }
				offset = (blocksDoneThisSet < kNumStates / 2) ? 0 : kNumStates / 2;
			}	
			else {
                for (state = kNumStates / 2, blocksDoneThisSet = 0; state < kNumStates; state++) {
                    blocksDoneThisSet += blockStatus.doneStates[state];
                }
				offset = (blocksDoneThisSet < kNumStates / 2) ? kNumStates / 2 : 0;
			}	
            do {                                                        // do remaining in/in condition
                blockStatus.attendState = (rand() % (kNumStates / 2)) + offset;
                NSLog(@"Set attendState to %ld", blockStatus.attendState);
            } while (blockStatus.doneStates[blockStatus.attendState] > 0);
		}
        blockStatus.attendLoc = blockStatus.attendState % (kNumStates / 2);
        if ([[task dataDoc] filePath] == nil) {                         // scramble only if no data file open
            [stimuli shuffleStimSequence];
        }
	}
}
