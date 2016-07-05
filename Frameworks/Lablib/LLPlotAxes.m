//
//  LLPlotAxes.m
//  Lablib
//
//  Created by John Maunsell on Sat May 03 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLPlotAxes.h"
#import "LLViewUtilities.h"

@implementation LLPlotAxes

// Draw an x axis

+ (void)drawXAxisWithScale:(LLViewScale *)scale from:(float)startX to:(float)stopX 
                atY:(float)y tickSpacing:(float)tickInt
                tickLabelSpacing:(long)labelInt tickLabels:(NSArray *)tickLabels 
                label:(NSString *)axisLabel {
				
    long index, textLineHeightPix, labelSpacing;
    float x;
    NSString *labelString;
	TickSettings ticks;
 	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    
// Draw the base axis
    
    textLineHeightPix = [layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]];
    [NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(startX, y)]
                toPoint:[scale scaledPoint:NSMakePoint(stopX, y)]];

// Label the axis

    [LLViewUtilities drawString:axisLabel centerAndBottomAtPoint:NSMakePoint([scale scaledX:(startX + stopX) /2.0], 
            [scale scaledY:y] - kTickHeightPix - 2 * textLineHeightPix) rotation:0.0 withAttributes:nil];

// Draw the tick marks

	if (tickInt <= 0) {
		[LLPlotAxes getTickLimits:&ticks style:(long)tickInt fromValue:startX toValue:stopX];
		labelSpacing = 1;
	}
	else {
		[LLPlotAxes getTickLimits:&ticks spacing:tickInt fromValue:startX toValue:stopX];
		labelSpacing = labs(labelInt);
	}	
	for (x = ticks.low; x <= ticks.high; x += ticks.inc) {
        [NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(x, y)]
                toPoint:NSMakePoint([scale scaledX:x], [scale scaledY:y] - kTickHeightPix)];
	}

// Label the ticks

	ticks.inc *= labelSpacing;
	for (x = ticks.low, index = 0; x <= ticks.high; x += ticks.inc, index++) {
        if (tickLabels == nil) {
            labelString = [NSString stringWithFormat:@"%.*f", [LLPlotAxes precisionForMin:startX andMax:stopX], x];
        }
        else {
            labelString = (index < [tickLabels count]) ? [tickLabels objectAtIndex:index] :  @"";
        }
        [LLViewUtilities drawString:labelString centerAndBottomAtPoint:NSMakePoint([scale scaledX:x], 
                [scale scaledY:y] - kTickHeightPix - textLineHeightPix) rotation:0.0 withAttributes:nil];
	}
}

// Draw an y axis

+ (void)drawYAxisWithScale:(LLViewScale *)scale from:(float)startY to:(float)stopY 
                atX:(float)x tickSpacing:(float)tickInt
                tickLabelSpacing:(long)labelInt tickLabels:(NSArray *)tickLabels
                label:(NSString *)axisLabel {

    long index, textLineHeightPix, labelSpacing;
    float y;
    NSString *labelString;
    BOOL rotateLabels;
	TickSettings ticks;
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    
// Draw the base axis
    
    textLineHeightPix = [layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]];
    [NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(x, startY)]
                toPoint:[scale scaledPoint:NSMakePoint(x, stopY)]];

// Label the axis

    [LLViewUtilities drawString:axisLabel 
            centerAndBottomAtPoint:NSMakePoint([scale scaledX:x] - kTickHeightPix - textLineHeightPix, 
            [scale scaledY:(startY + stopY) /2.0]) 
            rotation:90.0 withAttributes:nil];

// Draw the tick marks

	if (tickInt <= 0) {
		[LLPlotAxes getTickLimits:&ticks style:(long)tickInt fromValue:startY toValue:stopY];
		labelSpacing = 1;
	}
	else {
		[LLPlotAxes getTickLimits:&ticks spacing:tickInt fromValue:startY toValue:stopY];
		labelSpacing = labs(labelInt);
	}	
	for (y = ticks.low; y <= ticks.high; y += ticks.inc) {
		[NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(x, y)]
			toPoint:NSMakePoint([scale scaledX:x] - kTickHeightPix, [scale scaledY:y])];
	}

// Label the ticks

 //   [LLPlotAxes getTickLimits:&ticks spacing:labelSpacing fromValue:startY toValue:stopY];
	
// First check whether we need to rotate the labels

	ticks.inc *= labelSpacing;
	rotateLabels = NO;
    if (axisLabel != nil) {
        for (y = ticks.low; y <= ticks.high; y += ticks.inc) {
            labelString = [NSString stringWithFormat:@"%.*f", 
                        [LLPlotAxes precisionForMin:startY andMax:stopY], y];
            if ([labelString length] > 2) {
                rotateLabels = YES;
                break;
            }
        }
    }
	for (y = ticks.low, index = 0; y <= ticks.high; y += ticks.inc, index++) {
		if (tickLabels == nil) {
			labelString = [NSString stringWithFormat:@"%.*f", [LLPlotAxes precisionForMin:startY andMax:stopY], y];
        }
        else {
            labelString = (index < [tickLabels count]) ? [tickLabels objectAtIndex:index] :  @"";
        }
        if (rotateLabels) {
            [LLViewUtilities drawString:labelString 
                centerAndBottomAtPoint:NSMakePoint([scale scaledX:x] - kTickHeightPix, [scale scaledY:y]) 
                rotation:90.0 withAttributes:nil];
        }
        else {
            [LLViewUtilities drawString:labelString 
                rightAndCenterAtPoint:NSMakePoint([scale scaledX:x] - kTickHeightPix, [scale scaledY:y]) 
                rotation:0.0 withAttributes:nil];
        }
	}
}

// Return settings that will plot a specific style of ticks.  For the auto setting, we
// ensure that the axis will have between 2 and 5 ticks on the axis.

+ (void)getTickLimits:(TickSettings *)pTicks style:(long)style fromValue:(float)v1 toValue:(float)v2 {

	float minl, maxl, range, inc;

	minl = MIN(v1, v2);
	maxl = MAX(v1, v2);
	if (minl == maxl) {
		style = kNoTicks;
	}
	switch (style) {
	case kNoTicks:									// set for no drawing
		pTicks->low = pTicks->inc = 1;
		pTicks->high = 0;
		break;
	case kMaxMinTicks:								// set to label only limits of axis
		pTicks->low = minl;
		pTicks->high = maxl;
		pTicks->inc = maxl - minl;
		break;
	case kMaxOnlyTicks:								// set to label only limits of axis
		pTicks->low = maxl;
		pTicks->high = maxl;
		pTicks->inc = 1.0;
		break;
	case kMinOnlyTicks:								// set to label only limits of axis
		pTicks->low = minl;
		pTicks->high = maxl;
		pTicks->inc = 2.0 * (maxl - minl);
		break;
	case kAutoTicks:
	default:
		range = maxl - minl;
		inc = exp2((floor(log10(range) - 1) / log10(2.0)));
		for (;;) {
			if (range / inc <= 4.0) {			// decade increments
				break;
			}
			inc *= 2.0;						// 1/5 decade
			if (range / inc <= 5.0) {
				break;
			}
			inc *= 2.5;						// 1/2 decade increments
			if (range / inc <= 4.0) {
				break;
			}
			inc *= 2.0;						// decade increments again
		}
		[self getTickLimits:pTicks spacing:inc fromValue:v1 toValue:v2];
		break;
	}
}

// Get the beginning and end tick values that need to be plotted,
// based on start and stop values and the tick interval.

+ (void)getTickLimits:(TickSettings *)pTicks spacing:(float)tickSpacing fromValue:(float)v1 toValue:(float)v2 {

	float minl, maxl;
	
	minl = MIN(v1, v2);
	maxl = MAX(v1, v2);

    if (minl == maxl) {
        pTicks->low = pTicks->high = v1;
    }
    else {
        pTicks->low = (long)(minl / tickSpacing) * tickSpacing;
        if (minl > 0 && pTicks->low < minl) {
            pTicks->low += tickSpacing;
        }
        pTicks->high = (long)(maxl / tickSpacing) * tickSpacing;
        if (maxl < 0 && pTicks->high > maxl) {
            pTicks->high -= tickSpacing;
        }
    }
	pTicks->inc = tickSpacing;
}

// Return the number of digits of precision that the tick labels should 
// be displayed with.

+ (int) precisionForMin:(float)axisMinValue andMax:(float)axisMaxValue {

    long precision;
    float value;
    
	value = MAX(fabs(axisMinValue), fabs(axisMaxValue));
	if (value == 0) {
		precision = 1;
	}
    else {
        precision = 0;
        while (value < 9.99) {
            precision++;
            value *= 10.0;
        }
    }
    return precision;
}

+ (long) tickHeightPix {

    return kTickHeightPix;
}

@end
