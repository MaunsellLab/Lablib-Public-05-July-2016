//
//  LLEyeXYView.h
//  Lablib
//
//  Created by John Maunsell on Thu May 01 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLEyeWindow.h"
#import "LLEyeCalibrator.h"
#import "LLViewScale.h"

#define kAlphaLevels		8
#define kMaxSamplesDisplay	1000

#ifndef kEyes
enum {kLeftEye, kRightEye};
#define kEyes   (kRightEye + 1)
#endif

@interface LLEyeXYView:NSView {

	NSColor			*backgroundColor;
	NSRect			dirtyRectPix;
    BOOL			doDotFade;
	BOOL			doGrid;
	BOOL			doTicks;
    CGFloat			dotSizeDeg;
    NSMutableArray	*drawables;
	BOOL			drawOnlyDirtyRect;
	NSColor			*eyeColor[kEyes];
    NSMutableArray	*eyeWindows;
	NSColor			*gridColor;
	CGFloat			gridDeg;
    long			oneInN;
    NSMutableArray	*paths;
	NSColor			*pointColors[kEyes][kMaxSamplesDisplay];
	long			sampleCount[kEyes];
    NSLock			*sampleLock;
    NSMutableArray  *sampleRectsDeg[kEyes];
	long			samplesToSave;
	CGFloat			tickDeg;
}

- (void)addDrawable:(id <LLDrawable>)drawable;
- (void)addSample:(NSPoint)samplePointDeg;
- (void)addSample:(NSPoint)samplePointDeg forEye:(long)eyeIndex;
- (void)centerDisplay;
- (void)clearSamples;
- (CGFloat)dotSizeDeg;
- (void)drawPointsInRect:(NSRect)rect forEye:(long)eyeIndex;
- (NSColor *)eyeColor;
- (NSColor *)eyeLColor;
- (NSColor *)eyeRColor;
- (long)oneInN;
- (NSPoint)pixPointFromDegPoint:(NSPoint)eyePointDeg;
- (NSRect)pixRectFromDegRect:(NSRect)eyeRectDeg;
- (void)removeAllDrawables;
- (void)removeDrawable:(id <LLDrawable>)drawable;
- (void)setDoGrid:(BOOL)state;
- (void)setDotFade:(BOOL)state;
- (void)setDoDotFade:(BOOL)state;
- (void)setDotSizeDeg:(CGFloat)sizeDeg;
- (void)setDrawOnlyDirtyRect:(BOOL)state;
- (void)setEyeColor:(NSColor *)newColor;
- (void)setEyeColor:(NSColor *)newColor forEye:(long)eyeIndex;
- (void)setGridDeg:(CGFloat)spacingDeg;
- (void)setGrid:(BOOL)state;
- (void)setOneInN:(CGFloat)n;
- (void)setSamplesToSave:(long)samples;
- (void)setTickDeg:(CGFloat)spacingDeg;
- (void)setTicks:(BOOL)state;
- (void)updatePointColors;


@end
