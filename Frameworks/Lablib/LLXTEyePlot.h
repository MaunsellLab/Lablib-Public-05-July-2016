//
//  LLXTEyePlot.h
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTPlot.h"

@interface LLXTEyePlot : NSObject <LLXTPlot> {

    float			durationS;
	NSLock			*eyeLock;
	long			fixWindowOrigin;
	long			fixWindowWidth;
    NSColor			*lineColor;
	unsigned long	purgeCount;
    NSMutableArray	*sampleRectsDeg;
    LLViewScale		*scale;
    NSColor			*windowFillColor;
    NSColor			*windowStrokeColor;
}

- (void)addPoint:(NSPoint)eyePoint;
- (NSColor *)adjustedColor:(NSColor *)color factor:(float)factor;
- (void)clear;
- (void)drawEye;
- (void)drawWindow;
- (void)setEyeWindowOrigin:(float)origin width:(float)width;
- (void)setLineColor:(NSColor *)color;

@end
