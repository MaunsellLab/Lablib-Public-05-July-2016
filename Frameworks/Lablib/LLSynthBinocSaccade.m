//
//  LLSynthBinocSaccade.m
//  Lablib
//
//  Created by John Maunsell
//  Copyright (c) 2012. All rights reserved.
//

#import "LLSynthBinocSaccade.h"

#define kAccelDegPerSPerS		5000.0
#define	kCenteringProb			0.50
#define kPi                     3.14159

@implementation LLSynthBinocSaccade

- (BOOL)done;
{
    return (decelSteps[kLeftEye] == 0 && decelSteps[kRightEye] == 0);
}

- (id)initFrom:(NSPoint *)currentDeg degToUnits:(NSAffineTransform **)degToUnits samplePerMS:(long)samplePeriodMS;
{
    long distanceIndex;
    NSPoint targetDeg;
    float magDeg, dirRad;
    float distanceDeg[] = {2.0, 32.0};

    if ((self = [super init]) != nil) {
        
        // Select a magnitude for the saccade.  Pick a random size, and then a point in the
        // range between it and half its magnitude
        
        distanceIndex = (rand() % (sizeof(distanceDeg) / sizeof(float)));
        magDeg = (rand() % (long)(distanceDeg[distanceIndex] * 10)) / 10.0 - 
                                            (rand() % (long)(distanceDeg[distanceIndex]  * 0.875 * 10)) / 10.0;

        // Select a direction for the saccade.  kCenterProb determines the probability that the 
        // saccade will be in the direction of the center position ((0, 0) ±90°);
        
        if ((rand() % 100) < (kCenteringProb * 100)) {
            dirRad = atan2(-currentDeg[kLeftEye].y, -currentDeg[kLeftEye].x) + 
                                            ((rand() % 90) - 45) * kPi / 180.0;
        }
        else {
            dirRad = (rand() % 360) / 2.0 / kPi;
        }
        
        targetDeg.x = (currentDeg[kLeftEye].x + currentDeg[kRightEye].x) / 2.0 + cos(dirRad) * magDeg;
        targetDeg.y = (currentDeg[kLeftEye].y + currentDeg[kRightEye].y) / 2.0 + sin(dirRad) * magDeg;
        [self initParametersFrom:currentDeg to:targetDeg degToUnits:degToUnits samplePerMS:samplePeriodMS];   
    }
    return self;
}

- (id)initFrom:(NSPoint *)currentDeg to:(NSPoint)targetDeg degToUnits:(NSAffineTransform **)degToUnits
                                                                            samplePerMS:(long)samplePeriodMS;
{
    if ((self = [super init]) != nil) {
        [self initParametersFrom:currentDeg to:targetDeg degToUnits:degToUnits samplePerMS:samplePeriodMS];   
    }
    return self;
}

- (void)initParametersFrom:(NSPoint *)currentDeg to:(NSPoint)targetDeg degToUnits:(NSAffineTransform **)degToUnits
               samplePerMS:(long)samplePeriodMS;
{
    long eyeIndex;
    NSSize saccadeSizeUnits, unitsPerDeg;
    float accelDPSS, magDeg, magUnits, samplesPerS;

    samplesPerS = 1000.0 / samplePeriodMS;

//    NSLog(@"From %.1f %.1f and %.1f %.1f to %.1f %.1f", currentDeg[kLeftEye].x, currentDeg[kLeftEye].y,
//          currentDeg[kRightEye].x, currentDeg[kRightEye].y, targetDeg.x, targetDeg.y);
    
    
    for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
        currentPosition[eyeIndex] = [degToUnits[eyeIndex] transformPoint:currentDeg[eyeIndex]];
        magDeg = sqrt((targetDeg.x - currentDeg[eyeIndex].x) * (targetDeg.x - currentDeg[eyeIndex].x) +
                      (targetDeg.y - currentDeg[eyeIndex].y) * (targetDeg.y - currentDeg[eyeIndex].y));
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
        
        saccadeSizeUnits = [degToUnits[eyeIndex] 
                transformSize:NSMakeSize(targetDeg.x - currentDeg[eyeIndex].x, targetDeg.y - currentDeg[eyeIndex].y)];
        magUnits = sqrt((saccadeSizeUnits.width * saccadeSizeUnits.width) + 
                        (saccadeSizeUnits.height * saccadeSizeUnits.height));
        unitsPerDeg = [degToUnits[eyeIndex] transformSize:NSMakeSize(1.0, 1.0)];
        accelPerSample[eyeIndex].width = fabs(accelDPSS * unitsPerDeg.width) / samplesPerS / samplesPerS *
                    (saccadeSizeUnits.width / magUnits);
        accelPerSample[eyeIndex].height = fabs(accelDPSS * unitsPerDeg.height) / samplesPerS / samplesPerS *
                    (saccadeSizeUnits.height / magUnits);
        accelSteps[eyeIndex] = decelSteps[eyeIndex] = sqrt(fabs(magDeg / (accelDPSS / samplesPerS / samplesPerS)));
        stepSize[eyeIndex].width = stepSize[eyeIndex].height = 0;
    }
}

- (void)nextPositions:(NSPoint *)positions;
{
    long eyeIndex;
    
    for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
        if (accelSteps[eyeIndex] > 0) {
            stepSize[eyeIndex].width += accelPerSample[eyeIndex].width;
            stepSize[eyeIndex].height += accelPerSample[eyeIndex].height;
            accelSteps[eyeIndex]--;
        }
        else if (decelSteps[eyeIndex] > 0) {
            stepSize[eyeIndex].width -= accelPerSample[eyeIndex].width;
            stepSize[eyeIndex].height -= accelPerSample[eyeIndex].height;
            if (--decelSteps[eyeIndex] == 0) {
                stepSize[eyeIndex].width = stepSize[eyeIndex].height = 0;
            }
        }
        currentPosition[eyeIndex].x += stepSize[eyeIndex].width;
        positions[eyeIndex].x = currentPosition[eyeIndex].x = MIN(SHRT_MAX, MAX(SHRT_MIN, currentPosition[eyeIndex].x));
        currentPosition[eyeIndex].y += stepSize[eyeIndex].height;
        positions[eyeIndex].y = currentPosition[eyeIndex].y = MIN(SHRT_MAX, MAX(SHRT_MIN, currentPosition[eyeIndex].y));
    }
    if (accelSteps[eyeIndex] > 0) {
        accelSteps[eyeIndex]--;
    }
    else if (decelSteps[eyeIndex] > 0) {
        if (--decelSteps[eyeIndex] == 0) {
            stepSize[eyeIndex].width = stepSize[eyeIndex].height = 0;
        }
    }
}

@end
