//
//  LLEyeWindow.m
//  Lablib
//
//  Created by John Maunsell on Sun May 18 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLEyeWindow.h"


@implementation LLEyeWindow

- (float)azimuthDeg {

    return azimuthDeg;
}

- (NSPoint)centerDeg {

    return NSMakePoint(azimuthDeg, elevationDeg);
}

- (NSColor *)color {

    return plotColor;
}

- (float)elevationDeg {

    return elevationDeg;
}

-  (void)dealloc {

    [plotColor release];
	[super dealloc];
}

- (float)heightDeg {

    return rectDeg.size.height;
}

- (id)init {

    if ((self = [super init]) != nil) {
        plotColor = [[NSColor blueColor] retain];
    }
    return self;
}

- (BOOL)inWindowDeg:(NSPoint)pointDeg;
{
    return NSPointInRect(pointDeg, rectDeg);
}

- (NSPoint)originDeg {

    return rectDeg.origin;
}

- (float)radiusDeg {

    return radiusDeg;
}

- (NSRect)rectDeg {

    return rectDeg;
}

- (float)widthDeg {

    return rectDeg.size.width;
}

- (void)setAzimuthDeg:(double)azimuth {

    azimuthDeg = azimuth;
    [self setRectOrigin];
}

- (void)setAzimuthDeg:(double)azimuth elevationDeg:(double)elevation {

    azimuthDeg = azimuth;
    elevationDeg = elevation;
    [self setRectOrigin];
}

- (void)setColor:(NSColor *)color {

    [color retain];
    [plotColor release];
    plotColor = color;
}

- (void)setElevationDeg:(double)elevation {

    elevationDeg = elevation;
    [self setRectOrigin];
}

- (void)setHeightDeg:(double)height {

    rectDeg.size.height = height;
    radiusDeg = MIN(rectDeg.size.height, rectDeg.size.width);
    [self setRectOrigin];
}

- (void)setRadiusDeg:(double)radius {

    radiusDeg = rectDeg.size.height = rectDeg.size.width = radius;
}

- (void)setRectOrigin {

    rectDeg.origin.x = azimuthDeg - rectDeg.size.width / 2.0;
    rectDeg.origin.y = elevationDeg - rectDeg.size.height / 2.0;
}

- (void)setWidthAndHeightDeg:(double)value  {

    rectDeg.size.width = rectDeg.size.height = value;
    radiusDeg = MIN(rectDeg.size.height, rectDeg.size.width);
    [self setRectOrigin];
}

- (void)setWidthDeg:(double)width {

    rectDeg.size.width = width;
    radiusDeg = MIN(rectDeg.size.height, rectDeg.size.width);
    [self setRectOrigin];
}

- (void)setWidthDeg:(double)width heightDeg:(double)height {

    rectDeg.size.width = width;
    rectDeg.size.height = height;
    radiusDeg = MIN(rectDeg.size.height, rectDeg.size.width);
    [self setRectOrigin];
}

- (NSSize)sizeDeg {

    return rectDeg.size;
}

@end
