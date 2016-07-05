//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VI.h"
#import "UtilityFunctions.h"

#define kPrefRate			100.0
#define kSpontRate			15.0
#define kNullRate			20.0
#define kBeta

NSPoint azimuthAndElevationForStimLoc(StimLoc loc, TaskState state) {
    
    float polarAngleDeg, eccentricityDeg;
    NSPoint aziEle;
    
    eccentricityDeg = [[task defaults] floatForKey:VIEccentricityDegKey];
    //    polarAngleDeg = [[task defaults] floatForKey:VIAngleRF0DegKey];
    switch (loc) {
        case kGabor0:
        default:
            polarAngleDeg = [[task defaults] floatForKey:VIAngleRF0DegKey];
            break;
        case kGabor1:
            if (state <= kInInAttFar1) {         // In/In configuration
                polarAngleDeg = [[task defaults] floatForKey:VIAngleRF1DegKey];
            }
            else {                                  // In/Out configuration
                polarAngleDeg = [[task defaults] floatForKey:VIAngleRFOutDegKey];
            }
            break;
        case kGaborFar0:
            polarAngleDeg = [[task defaults] floatForKey:VIAngleRF0DegKey] + 180.0;
            break;
        case kGaborFar1:
            if (state <= kInInAttFar1) {         // In/In configuration
                polarAngleDeg = [[task defaults] floatForKey:VIAngleRF1DegKey] + 180.0;
            }
            else {                                  // In/Out configuration
                polarAngleDeg = [[task defaults] floatForKey:VIAngleRFOutDegKey] + 180.0;
            }
            break;
    }
    aziEle.x = eccentricityDeg * cos(polarAngleDeg / kDegPerRadian);
    aziEle.y = eccentricityDeg * sin(polarAngleDeg / kDegPerRadian);
    return aziEle;
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

