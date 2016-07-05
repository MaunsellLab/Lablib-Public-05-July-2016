//
//  SCUtilities.m
//  SpotChange
//
//  Created by John Maunsell on 6/23/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "SCUtilities.h"
#include "SC.h"

enum {kUseLeftEye = 0, kUseRightEye, kUseBinocular};

NSString *SCEyeToUseKey = @"VIEyeToUse";

@implementation SCUtilities
/*
+ (void)announceEvents;
{    
    long lValue;
    float floatValue;
	char *idString = "VICAN Version 1.0";
	
    [self reset];
	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];
    
	[[task dataDoc] putEvent:@"gabor" withData:(Ptr)[[stimuli gabor] gaborData]];
    floatValue = [[task defaults] floatForKey:VIEccentricityDegKey];
	[[task dataDoc] putEvent:@"eccentricityDeg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VIAngleRF0DegKey];
	[[task dataDoc] putEvent:@"polarAngleRF0Deg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VIAngleRF1DegKey];
	[[task dataDoc] putEvent:@"polarAngleRF1Deg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:VIAngleRFOutDegKey];
	[[task dataDoc] putEvent:@"polarAngleRFOutDeg" withData:(Ptr)&floatValue];
    
    lValue = [[task defaults] integerForKey:VIStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VIPrecueMSKey];
	[[task dataDoc] putEvent:@"precueMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VIPreStimMSKey];
	[[task dataDoc] putEvent:@"preStimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VIInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VIStimLeadMSKey];
	[[task dataDoc] putEvent:@"stimLeadMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VIRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VITooFastMSKey];
	[[task dataDoc] putEvent:@"tooFastTimeMS" withData:(Ptr)&lValue];
	lValue = [[task defaults] integerForKey:VIStimRepsPerBlockKey];
	[[task dataDoc] putEvent:@"stimRepsPerBlock" withData:(void *)&lValue];
	lValue = [[task defaults] integerForKey:VIMaxTargetMSKey];
	[[task dataDoc] putEvent:@"maxTargetMS" withData:(void *)&lValue];
}
*/

+ (BOOL)inWindow:(LLEyeWindow *)window;
{
    BOOL inWindow = NO;
    
    switch ([[task defaults] integerForKey:SCEyeToUseKey]) {
        case kUseLeftEye:
        default:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]];
            break;
        case kUseRightEye:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
        case kUseBinocular:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]] && 
                                    [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
    }
    return inWindow;
}
/*
+ (void)reset;
{    
    long resetType = 0;
    
	[[task dataDoc] putEvent:@"reset" withData:&resetType];
}

+ (void)requestReset;
{
    if ([task mode] == kTaskIdle) {
        [self reset];
    }
    else {
        resetFlag = YES;
    }
}

+ (NSString *)stringForStimDescEntry:(NSArray *)stimList entryIndex:(long)index;
{
    long stimIndex;
    NSString *string;
    StimDesc stimDesc;
    
    [[stimList objectAtIndex:index] getValue:&stimDesc];
    string = @"";
    for (stimIndex = 0; stimIndex < kStimLocs; stimIndex++) {
        if (stimDesc.listTypes[stimIndex] == kTargetStim) {
            if (stimIndex == stimDesc.attendLoc) {
                string = [NSString stringWithFormat:@"VT%@", string];
            }
            else  {
                string = [NSString stringWithFormat:@"%@IT", string];
            }
        }
    }
    if ([string isEqualToString:@""]) {
        stimIndex = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];
        string = [NSString stringWithFormat:@"%2ld", stimIndex];       
    }
    return string;
}

+ (void)updateBlockStatus:(BlockStatus *)pBS;
{
    long index, stim, state, offset, blocksDoneThisSet;
	NSArray *changeArray;
	NSDictionary *entryDict;

    pBS->numChanges = [[task defaults] integerForKey:VIAlphaChangesKey];
    pBS->stimPerState = kStimPerState;
    changeArray = [[task defaults] arrayForKey:VIAlphaChangeArrayKey];
    for (index = 0; index < pBS->numChanges; index++) {
        entryDict = [changeArray objectAtIndex:index];
        pBS->changes[index] = [[entryDict valueForKey:VIChangeKey] floatValue];
    }
    
    //Give extra repetitions for the most difficult attentional states:
    if (trial.attendState < 2 || trial.attendState == 4 || trial.attendState == 5) {
        pBS->presPerState = pBS->stimPerState * ([[task defaults] integerForKey:VIStimRepsPerBlockKey] + [[task defaults]integerForKey:VIExtraDifficultStimRepsKey]);
    }
    else {
        pBS->presPerState = pBS->stimPerState * [[task defaults] integerForKey:VIStimRepsPerBlockKey];
    }
	pBS->presDoneThisState = -(pBS->blocksDone * pBS->presPerState);
	pBS->statesPerBlock = kNumStates;
	pBS->blockLimit = [[task defaults] integerForKey:VIBlockLimitKey];
	for (stim = 0; stim < kStimPerState; stim++) {
        pBS->presDoneThisState += stimDone[pBS->attendState][stim];
	}
	
    // If we've finished the presentations for this state, we need to pick a new state
	
	if (pBS->presDoneThisState >= pBS->presPerState) {
		pBS->doneStates[pBS->attendState]++;
		pBS->instructsDone = 0;
		pBS->presDoneThisState = 0;
		
        // If we've finished all states for this block, then we need to advance to the next block and
        // pick a random state
		
		if (++pBS->statesDoneThisBlock >= pBS->statesPerBlock) {
			pBS->blocksDone++;
			pBS->statesDoneThisBlock = 0;
			for (state = 0; state < kNumStates; state++) {
				pBS->doneStates[state] = 0;
			}
            if (pBS->attendState < kNumStates / 2) {          // switch to the other condition at block end
                pBS->attendState = (rand() % (kNumStates / 2)) + (kNumStates / 2);
                NSLog(@"Set attendState to %ld", pBS->attendState);
            }
            else {
                pBS->attendState = (rand() % (kNumStates / 2));
                NSLog(@"Set attendState to %ld", pBS->attendState);
            }
		}
		else {
			if (pBS->attendState < kNumStates / 2) {
                for (state = blocksDoneThisSet = 0; state < kNumStates / 2; state++) {
                    blocksDoneThisSet += pBS->doneStates[state];
                }
				offset = (blocksDoneThisSet < kNumStates / 2) ? 0 : kNumStates / 2;
			}
			else {
                for (state = kNumStates / 2, blocksDoneThisSet = 0; state < kNumStates; state++) {
                    blocksDoneThisSet += pBS->doneStates[state];
                }
				offset = (blocksDoneThisSet < kNumStates / 2) ? kNumStates / 2 : 0;
			}
            do {                                                        // do remaining in/in condition
                pBS->attendState = (rand() % (kNumStates / 2)) + offset;
                NSLog(@"Set attendState to %ld", pBS->attendState);
            } while (pBS->doneStates[pBS->attendState] > 0);
		}
        pBS->attendLoc = pBS->attendState % (kNumStates / 2);
        if ([[task dataDoc] filePath] == nil) {                         // scramble only if no data file open
            [stimuli shuffleStimSequence];
        }
	}
}
*/

@end
