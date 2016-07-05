//
//  LLStimWindow.h
//  Lablib
//
//  Created by John Maunsell on Sun May 04 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLDisplays.h"
#import "LLIntervalMonitor.h"

@interface LLStimWindow : NSWindow <NSWindowDelegate> { 

@protected
	double					contrast;
	DisplayParam			display;
	long					displayIndex;
	LLDisplays				*displays;
	long					durationMS;
	BOOL					fullscreen;
	LLIntervalMonitor 		*monitor;
	NSLock					*openGLLock;
	NSPoint					scaleOffsetDeg;
	NSOpenGLContext 		*stimOpenGLContext;
	BOOL					stimulating;
}

- (NSPoint)centerPointPix;
- (NSPoint)centerPointPixLLOrigin;
- (NSPoint)degPointFromPixPoint:(NSPoint)pointPix;
- (NSSize)degSizeFromPixSize:(NSSize)sizePix;
- (DisplayParam)display;
- (long)displayIndex;
- (DisplayParam *)displayParameters;
- (NSRect)displayRectDeg;
- (NSSize)displaySizeDeg;
- (LLDisplays *)displays;
- (void)erase;
- (void)flushBuffer;
- (float)frameRateHz;
- (BOOL)fullscreen;
- (void)grayScreen;
- (void)lock;
- (LLIntervalMonitor *)monitor;
- (BOOL)mouseInside;
- (NSPoint)mouseLocationDeg; 
- (NSPoint)pixPointFromDegPoint:(NSPoint)pointDeg;
- (NSSize)pixSizeFromDegSize:(NSSize)sizeDeg;
- (void)scaleDisplay;
- (NSPoint)scaleOffsetDeg;
- (void)setScaleOffsetDeg:(NSPoint)offsetDeg;
- (BOOL)setDisplayMode:(DisplayModeParam)mode;
- (void)showDisplayParametersPanel;
- (void)unlock;

@end
