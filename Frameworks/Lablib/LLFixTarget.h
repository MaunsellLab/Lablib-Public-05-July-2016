//
//  LLFixTarget.h
//  Lablib
//
//  Created by John Maunsell on Thu Feb 12 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLVisualStimulus.h"

enum {kLLCircle, kLLSquare, kLLDiamond, kLLCross, kLLShapes};

extern NSString *LLFixAzimuthDegKey;
extern NSString *LLFixBackColorKey;
extern NSString *LLFixDirectionDegKey;
extern NSString *LLFixElevationDegKey;
extern NSString *LLFixForeColorKey;
extern NSString *LLFixKdlThetaDegKey;
extern NSString *LLFixKdlPhiDegKey;
extern NSString *LLFixRadiusDegKey;

extern NSString *LLFixInnerRadiusDegKey; 
extern NSString *LLFixShapeKey; 

@interface LLFixTarget : LLVisualStimulus {

	float		innerRadiusDeg;
	long		shape;
}

- (void)drawCircleWithRadius:(float)radiusDeg;
- (void)drawRectWithWidthDeg:(float)widthDeg lengthDeg:(float)lengthDeg;
- (NSColor *)fixTargetColor;
- (float)innerRadiusDeg;
- (float)outerRadiusDeg;
- (void)setFixTargetColor:(NSColor *)newColor;
- (void)setInnerRadiusDeg:(float)radiusDeg;
- (void)setOnRed:(float)red green:(float)green blue:(float)blue;
- (void)setOuterRadiusDeg:(float)radiusDeg;
- (void)setShape:(long)shape;
- (long)shape;

@end
