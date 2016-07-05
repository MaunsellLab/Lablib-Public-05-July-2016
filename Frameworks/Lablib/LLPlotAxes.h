//
//  LLPlotAxes.h
//  Lablib
//
//  Created by John Maunsell on Sat May 03 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewScale.h"

#define kMaxTicks			100
#define kTickHeightPix		5

#define kNoTicks			0
#define kMaxMinTicks		-1
#define kMaxOnlyTicks		-2
#define kMinOnlyTicks		-3
#define	kAutoTicks			-4

typedef struct {
	float low;
	float high;
	float inc;
} TickSettings;

@interface LLPlotAxes : NSObject {

}

+ (void)drawXAxisWithScale:(LLViewScale *)scale from:(float)startX to:(float)stopX 
                atY:(float)y tickSpacing:(float)tickInt
                tickLabelSpacing:(long)labelInt tickLabels:(NSArray *)tickLabels
                label:(NSString *)axisLabel;
+ (void)drawYAxisWithScale:(LLViewScale *)scale from:(float)startY to:(float)stopY 
                atX:(float)x tickSpacing:(float)tickInt
                tickLabelSpacing:(long)labelInt tickLabels:(NSArray *)tickLabels
                label:(NSString *)axisLabel;
+ (void)getTickLimits:(TickSettings *)pTicks spacing:(float)tickSpacing fromValue:(float)v1 toValue:(float)v2;
+ (void)getTickLimits:(TickSettings *)pTicks style:(long)style fromValue:(float)v1 toValue:(float)v2;
+ (int)precisionForMin:(float)axisMinValue andMax:(float)axisMaxValue;
+ (long)tickHeightPix;

@end
