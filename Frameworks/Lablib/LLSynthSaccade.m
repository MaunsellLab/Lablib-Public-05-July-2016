//
//  LLSynthSaccade.m
//  Lablib
//
//  Created by John Maunsell on Mon May 19 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSynthSaccade.h"

#define kAccelDegPerSPerS		5000.0
#define	kCenteringProb			0.50
#define kPi                     3.14159

@implementation LLSynthSaccade

- (BOOL)done;
{
    return (decelSteps == 0);
}

- (id)initFrom:(NSPoint)current samplePerMS:(long)samplePeriodMS unitsPerDeg:(float)calibration;
{
    long distanceIndex;
    double magDeg;
    double distanceDeg[] = {2.0, 32.0};

    if ((self = [super init]) != nil) {
        currentPosition = current;
        samplesPerS = 1000.0 / samplePeriodMS;
		unitsPerDeg = calibration;
		
// Select a magnitude for the saccade.  Pick a random size, and then a point in the
// range between it and half its magnitude
    
        distanceIndex = (rand() % (sizeof(distanceDeg) / sizeof(double)));
        magDeg = (rand() % (long)(distanceDeg[distanceIndex] * 10)) / 10.0 - 
                (rand() % (long)(distanceDeg[distanceIndex]  * 0.875 * 10)) / 10.0;
        magnitudeUnits = unitsPerDeg * magDeg;
 
// Select a direction for the saccade.  kCenterProb determines the probability that the 
// saccade will be in the direction of the center position ((0, 0) ±90°);
    
       if ((rand() % 100) < (kCenteringProb * 100)) {
            dirRad = atan2(-currentPosition.y, -currentPosition.x) + ((rand() % 90) - 45) * kPi / 180.0;
        }
        else {
            dirRad = (rand() % 360) / 2.0 / kPi;
        }
        [self initParameters];
    }
    return self;
}

- (id)initFrom:(NSPoint)current to:(NSPoint)target samplePerMS:(long)samplePeriodMS unitsPerDeg:(float)calibration;
{
    double xDelta, yDelta;
    
    if ((self = [super init]) != nil) {
        currentPosition = current;
        samplesPerS = 1000.0 / samplePeriodMS;
		unitsPerDeg = calibration;
        xDelta = current.x - target.x;
        yDelta = current.y - target.y;
        magnitudeUnits = sqrt(xDelta * xDelta + yDelta * yDelta);
        dirRad = atan2(target.y - current.y, target.x - current.x);
        [self initParameters];
    }
    return self;
}

// Set up saccade parameters.  Assumes the following have already been set: dirRad, magnitudeUnits

- (void)initParameters;
{
    double stepAccelPerSample, accelDPSS, magDeg;

    xStepSize = yStepSize = 0;
	magDeg = fabs(magnitudeUnits / unitsPerDeg);
	if (magDeg < 1.0) {
		accelDPSS = kAccelDegPerSPerS / 8;
	}
	else if (magDeg < 2.0) {
		accelDPSS = kAccelDegPerSPerS / 4;
	}
	else if (magDeg < 4.0) {
		accelDPSS = kAccelDegPerSPerS / 2;
	}
	else {
		accelDPSS = kAccelDegPerSPerS;
	}
	stepAccelPerSample = fabs(accelDPSS * unitsPerDeg) / samplesPerS / samplesPerS;
	stepAccelPerSample = 0.90 * stepAccelPerSample + 
							0.20 * stepAccelPerSample * (rand() % 1000) / 1000.0;
    xStepAccelPerSample = cos(dirRad) * stepAccelPerSample;
    yStepAccelPerSample = sin(dirRad) * stepAccelPerSample;
    accelSteps = decelSteps = sqrt(fabs(magnitudeUnits / stepAccelPerSample));
}

- (NSPoint)nextPosition;
{
    if (accelSteps > 0) {
        xStepSize += xStepAccelPerSample;
        yStepSize += yStepAccelPerSample;
        accelSteps--;
    }
    else if (decelSteps > 0) {
        xStepSize -= xStepAccelPerSample;
        yStepSize -= yStepAccelPerSample;
        decelSteps--;
    }
    currentPosition.x += xStepSize;
    currentPosition.x = MIN(SHRT_MAX, MAX(SHRT_MIN, currentPosition.x));
    currentPosition.y += yStepSize;
    currentPosition.y = MIN(SHRT_MAX, MAX(SHRT_MIN, currentPosition.y));
    return currentPosition;
}

@end
