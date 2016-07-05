//
//  LLXTEyePlot.m
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLXTEyePlot.h"

#define kStrokeFactor	0.50
#define kFillFactor 	0.05
#define kPurgePeriod	100

@implementation LLXTEyePlot

- (void)addPoint:(NSPoint)eyePoint;
{
    unsigned long index, limitTime;

	[eyeLock lock];

// Clear out any old events every so often

	if (((++purgeCount % kPurgePeriod) == 0) && [sampleRectsDeg count] > 0) {
		limitTime = [[sampleRectsDeg lastObject] pointValue].y - durationS * 1000.0;
		for (index = 0; index < [sampleRectsDeg count]; index++) {
			if ([[sampleRectsDeg objectAtIndex:index] pointValue].y >= limitTime) {
				break;
			}
		}
		if (index > 0) {
			[sampleRectsDeg removeObjectsInRange:NSMakeRange(0, index)];
		}
	}

// Add the new event

    [sampleRectsDeg addObject:[NSValue valueWithPoint:eyePoint]];
	[eyeLock unlock];
}

- (NSColor *)adjustedColor:(NSColor *)color factor:(float)factor;
{
    CGFloat red, green, blue, alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    red = 1.0 - (1.0 - red) * factor;
    green = 1.0 - (1.0 - green) * factor;
    blue = 1.0 - (1.0 - blue) * factor;
    return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0];
}    

- (void)clear;
{
	[eyeLock lock];
    [sampleRectsDeg removeAllObjects];
	[eyeLock unlock];
}

- (void)dealloc;
{
    [sampleRectsDeg release];
	[eyeLock release];
	[lineColor release];
    [super dealloc];
}

// Draw the XT plot.  This method sound only be called from with the drawRect method of
// an NSView

- (void)drawEye;
{
    unsigned long index;
    NSPoint p;
    NSBezierPath *path;
    
	[eyeLock lock];
	
// Draw the eye positions

    if ([sampleRectsDeg count] >= 2) {
        path = [[NSBezierPath alloc] init];
        p = [scale scaledPoint:[[sampleRectsDeg objectAtIndex:0] pointValue]];
        [path moveToPoint:p];
        for (index = 1; index < [sampleRectsDeg count]; index++) {
            p = [scale scaledPoint:[[sampleRectsDeg objectAtIndex:index] pointValue]];
            [path lineToPoint:p];
        }
        [lineColor set];
        [path stroke];
        [path release];
    }
	[eyeLock unlock];
}

- (void)drawWindow;
{
    NSRect r;

	[eyeLock lock];
    if (fixWindowWidth > 0) {
        r = [scale scaledRect:NSMakeRect(fixWindowOrigin, [scale yOrigin], fixWindowWidth, [scale height])];
        [windowFillColor set];
        [NSBezierPath fillRect:r];
        [windowStrokeColor set];
        [NSBezierPath strokeRect:r];
    }
	[eyeLock unlock];
}

- (void)setEyeWindowOrigin:(float)origin width:(float)width;
{
    fixWindowOrigin = origin;
    fixWindowWidth = width;
}

- (id)init;
{
	if ((self = [super init]) != nil) {
        sampleRectsDeg = [[NSMutableArray alloc] init];
        eyeLock = [[NSLock alloc] init];
        [self setLineColor:[NSColor blueColor]];
		durationS = 5;								// ??? This should be handled better
	}
	return self;
}

- (void)setDurationS:(NSNumber *)durS;
{
    durationS = [durS floatValue];
}

- (void)setLineColor:(NSColor *)color;
{
	if (color == lineColor) {
		return;
	}
    [color retain];
    if (lineColor != nil) {
        [lineColor release];
        [windowFillColor release];
        [windowStrokeColor release];
    }
    lineColor = color;
    windowStrokeColor =[self adjustedColor:lineColor factor:kStrokeFactor];
    [windowStrokeColor retain];
    windowFillColor =[self adjustedColor:lineColor factor:kFillFactor];
    [windowFillColor retain];
}

- (void)setScale:(LLViewScale *)scaling;
{
	if (scaling == scale) {
		return;
	}
    [scaling retain];
	[scale release];
    scale = scaling;
}

@end
