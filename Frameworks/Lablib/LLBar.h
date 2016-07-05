//
//  LLBar.h
//
//  Created by John Maunsell on Sat Feb 15 2003.
//  Copyright (c) 2006. All rights reserved.
//

#import "LLVisualStimulus.h"

extern NSString *LLBarAzimuthDegKey;
extern NSString *LLBarBackColorKey;
extern NSString *LLBarDirectionDegKey;
extern NSString *LLBarElevationDegKey;
extern NSString *LLBarForeColorKey;
extern NSString *LLBarKdlThetaDegKey;
extern NSString *LLBarKdlPhiDegKey;
extern NSString *LLBarRadiusDegKey;

extern NSString *LLBarLengthDegKey;
extern NSString *LLBarWidthDegKey;

@interface LLBar : LLVisualStimulus {

	float		lengthDeg;
	float		widthDeg;
}

- (float)lengthDeg;
- (void)setLengthDeg:(float)length;
- (void)setOrientationDeg:(float)newOri;
- (void)setWidthDeg:(float)width;
- (float)widthDeg;

@end

