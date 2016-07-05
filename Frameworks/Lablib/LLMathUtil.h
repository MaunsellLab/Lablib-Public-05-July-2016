//
//  LLMathUtil.h
//  Lablib
//
//  Created by John Maunsell on 2/8/07.
//  Copyright 2007. All rights reserved.
//

@interface LLMathUtil : NSObject {

}

+ (NSPoint)azimuthAndElevationFromEccentricity:(float)eccDeg andPolarAngleDeg:(float)polarAngleDeg;
+ (NSPoint)eccentricityAndPolarAngleFromAzimuth:(float)aziDeg andElevation:(float)eleDeg;

@end
