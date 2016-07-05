//
//  LLMathUtil.m
//  Lablib
//
//  Created by John Maunsell on 2/8/07.
//  Copyright 2007. All rights reserved.
//

#import "LLMathUtil.h"

#define kPI						(atan(1) * 4)
#define kDegPerRadian			(180.0 / kPI)

@implementation LLMathUtil

+ (NSPoint)azimuthAndElevationFromEccentricity:(float)eccDeg andPolarAngleDeg:(float)polarAngleDeg;
{
	float polarAngleRad;
	NSPoint aziEle;

	polarAngleRad = polarAngleDeg / kDegPerRadian;
	aziEle.x = eccDeg * cos(polarAngleRad);
	aziEle.y = eccDeg * sin(polarAngleRad);
	return aziEle;
}

+ (NSPoint)eccentricityAndPolarAngleFromAzimuth:(float)aziDeg andElevation:(float)eleDeg;
{
	NSPoint eccPol;

	eccPol.x = sqrt(aziDeg * aziDeg + eleDeg * eleDeg);
	eccPol.y = kDegPerRadian * atan2(aziDeg / kDegPerRadian, eleDeg / kDegPerRadian);
	return eccPol;
}



@end
