//
//  LLViewScale.m
//  Lablib
//
//  Created by John Maunsell on Fri May 02 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewScale.h"
#define kDefaultUserHeight	1.0
#define kDefaultUserWidth	1.0
#define kInsideFactor		0.75
#define kClearanceFraction	0.15			// Desired full scale relative to closest plot value
#define kOutsideFactor		0.90

@implementation LLViewScale

// Automatically adjust the maximum or minimum scaled y value to keep plots in a good viewing range.
// Because each LLViewScale may be used by multiple views, we keep an array of views that
// call this method, and keep track of the maximum across all those views.  

- (BOOL)autoAdjustYMin:(float)yMin yMax:(float)yMax object:(id)obj {

	BOOL newScale;
    long objectIndex;
    float grandMax, grandMin, scaledYMax, scaledYMin, scaledHeight;
	float newYMax, newYMin;
    NSEnumerator *enumerator;
    NSNumber *number;

	if (isinf(yMin) || isinf(yMax)) {
		return NO;
	}
	
// Update the yMax and yMin values regardless of the state of autoAdjustYMax and autoAdjustYMin,
// in case they becomes true later

    objectIndex = [yMaxMinViewArray indexOfObject:obj];			// get the index of this view
    if (objectIndex != NSNotFound) {							// if it exists, temporarily remove it from the lists
        [yMaxMinViewArray removeObjectAtIndex:objectIndex];
        [yMaxs removeObjectAtIndex:objectIndex];
        [yMins removeObjectAtIndex:objectIndex];
    }
    [yMaxMinViewArray addObject:obj];							// update the view id and yMax
    [yMaxs addObject:[NSNumber numberWithFloat:yMax]];
    [yMins addObject:[NSNumber numberWithFloat:yMin]];

	if (!autoAdjustYMax && !autoAdjustYMin) {
		return NO;
	}

// Find the the extreme yMax and yMin across all view that use this scale

    enumerator = [yMaxs objectEnumerator];
    grandMax = -FLT_MAX;
    while (number = [enumerator nextObject]) {
        grandMax = MAX(grandMax, [number floatValue]);
    }
    enumerator = [yMins objectEnumerator];
    grandMin = FLT_MAX;
    while (number = [enumerator nextObject]) {
        grandMin = MIN(grandMin, [number floatValue]);
    }

// Adjust the maximum and minimum if needed

    newYMax = scaledYMax = NSMaxY(scaleRect); 
    newYMin = scaledYMin = NSMinY(scaleRect);
	scaledHeight = NSHeight(scaleRect);
	if ((scaledHeight == 0) || (grandMin == grandMax)) {	// not worth messing with
		return NO;
	}
	if (!autoAdjustYMin && (grandMax < scaledYMin)) {		// can't adjust max to be < min
		return NO;
	}
	if (!autoAdjustYMax && (grandMin > scaledYMax)) {		// can't adjust min to be > max
		return NO;
	}

// If we are adjusting just one limit, we must force the other to its current value,
// and change the grandMax/grandMin so that the tests and computations will not lead
// to an infinite recursion, which can happen if the rescaling is computed based on the
// range between the yMax and yMin, rather than the yMax or yMin and the fixed value
 
	if (!autoAdjustYMin) {									// adjust minimum?
		grandMin = scaledYMin;
	}
	if (!autoAdjustYMax) {									// adjust maximum?
		grandMax = scaledYMax;
	}
	
// If we are changing both limits, we change them both whenever either exceeds the 
// accepted range.  If we change only one, we can get into infinite recursion, because
// changing one can move the other second of range, then changing the second can move
// the first out, etc.

	newScale = NO;
	if (autoAdjustYMin) {
		if((grandMin > scaledYMax - kInsideFactor * scaledHeight) ||
					(grandMin < scaledYMax - kOutsideFactor * scaledHeight)) {
			newYMin = grandMin - (grandMax - grandMin) * kClearanceFraction;
			if (autoAdjustYMax) {
				newYMax = grandMax + (grandMax - grandMin) * kClearanceFraction;
			}
			newScale = YES;
		}
    }
	if (autoAdjustYMax && !newScale) {						// adjust maximum?
		if ((grandMax < scaledYMin + kInsideFactor * scaledHeight) ||
					(grandMax > scaledYMin + kOutsideFactor * scaledHeight)) {
			newYMax = grandMax + (grandMax - grandMin) * kClearanceFraction;
			if (autoAdjustYMin) {
				newYMin = grandMin - (grandMax - grandMin) * kClearanceFraction;
			}
			newScale = YES;
		}
    }
	/*
	if (autoAdjustYMin) {
		if((grandMin > scaledYMax - kInsideFactor * scaledHeight) ||
					(grandMin < scaledYMax - kOutsideFactor * scaledHeight)) {
			newYMin = grandMin - (grandMax - grandMin) * kClearanceFraction;
			newScale = YES;
		}
    }
	if (autoAdjustYMax) {									// adjust maximum?
		if ((grandMax < scaledYMin + kInsideFactor * scaledHeight) ||
					(grandMax > scaledYMin + kOutsideFactor * scaledHeight)) {
			newYMax = grandMax + (grandMax - grandMin) * kClearanceFraction;
			newScale = YES;
		}
    }
	*/
	
	if (newScale) {
		scaleRect.origin.y = newYMin;
		scaleRect.size.height = newYMax - newYMin;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"LLYScaleChanged" 
					object:self];
	}
	return newScale;
}

- (void) dealloc {

    [yMaxMinViewArray release];
    [yMaxs release];
    [yMins release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"LLViewScale (%lx): xMin %f xMax %f yMin %f yMax %f", (unsigned long)&self,
            scaleRect.origin.x, scaleRect.origin.y, scaleRect.size.width, scaleRect.size.height];
}
 
- (float)height {

    return scaleRect.size.height;
}
   
- (id) init {

    [super init];
    scaleRect = NSMakeRect(0.0, 0.0, kDefaultUserWidth, kDefaultUserHeight);
    yMaxMinViewArray = [[NSMutableArray alloc] init];
    yMaxs = [[NSMutableArray alloc] init];
    yMins = [[NSMutableArray alloc] init];
	autoAdjustYMax = autoAdjustYMin = YES;
    return self;
}

- (long)pixYInc:(float)yScaledInc {

    return scaleRect.size.height * yScaledInc / viewRect.size.height;
}

- (NSRect) scaleRect {

    return scaleRect;
}

- (NSPoint)scaledPoint:(NSPoint)userPoint {

    return NSMakePoint(viewRect.origin.x + (((userPoint.x - scaleRect.origin.x) * 
            viewRect.size.width) / scaleRect.size.width),
            viewRect.origin.y + (((userPoint.y - scaleRect.origin.y) * 
            viewRect.size.height) / scaleRect.size.height));
}

- (NSRect)scaledRect:(NSRect)userRect {

    return NSMakeRect(
        viewRect.origin.x + (((userRect.origin.x - scaleRect.origin.x) * viewRect.size.width) / scaleRect.size.width),
        viewRect.origin.y + (((userRect.origin.y - scaleRect.origin.y) * viewRect.size.height) / scaleRect.size.height),
        viewRect.size.width * userRect.size.width / scaleRect.size.width,  
        viewRect.size.height * userRect.size.height / scaleRect.size.height);
}

- (long)scaledX:(float)x {

    return viewRect.origin.x + (((x - scaleRect.origin.x) * 
            viewRect.size.width) / scaleRect.size.width);
}

- (long)scaledXInc:(float)xScaledInc {

    return viewRect.size.width * xScaledInc / scaleRect.size.width;
}

- (long)scaledY:(float)y {

    return viewRect.origin.y + (((y - scaleRect.origin.y) * 
            viewRect.size.height) / scaleRect.size.height);
}

- (long)scaledYInc:(float)yScaledInc {

    return viewRect.size.height * yScaledInc / scaleRect.size.height;
}

- (void) setAutoAdjustYMax:(BOOL)state {

    autoAdjustYMax = state;
}

- (void) setAutoAdjustYMin:(BOOL)state {

    autoAdjustYMin = state;
}

- (void) setHeight:(float)height {

    scaleRect.size.height = height;
}

- (void)setScaleRect:(NSRect)rect {

    scaleRect = rect;
}

- (void)setWidth:(float)width {

    scaleRect.size.width = width;
}

- (void)setXOrigin:(float)xOrigin {

    scaleRect.origin.x = xOrigin;
}

- (void)setXOrigin:(float)xOrigin width:(float)width {

    scaleRect.origin.x = xOrigin;
    scaleRect.size.width = width;
}

- (void)setYOrigin:(float)yOrigin {

    scaleRect.origin.y = yOrigin;
}

- (void)setYOrigin:(float)yOrigin height:(float)height {

    scaleRect.size.height = height;
    scaleRect.origin.y = yOrigin;
}

- (void)setViewRectForScale:(NSRect)rectPix {

    viewRect = rectPix;
}

- (NSRect)viewRect {

    return viewRect;
}

- (float)width {

    return scaleRect.size.width;
}

- (float)xMax {

    return scaleRect.origin.x + scaleRect.size.width;
}

- (float)xMin {

    return scaleRect.origin.x;
}

- (float)yMax {

    return scaleRect.origin.y + scaleRect.size.height;
}

- (float)yMin {

    return scaleRect.origin.y;
}

- (float)xOrigin {

    return scaleRect.origin.x;
}

- (float)yOrigin {

    return scaleRect.origin.y;
}

@end
