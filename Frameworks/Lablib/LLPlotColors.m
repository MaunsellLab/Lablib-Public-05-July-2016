//
//  LPlotLColors.m
//  Lablib
//
//  Created by John Maunsell on Tue May 06 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLPlotColors.h"

static float colorValues[][kGuns] = {
    {0.0, 0.0, 1.0},		// blue
    {0.0, 0.7, 0.0},		// green
    {0.9, 0.0, 0.0},		// red
    {0.7, 0.0, 0.7},		// purple
    {0.6, 0.4, 0.2},		// brown
    {0.0, 0.0, 0.0},		// black
    {0.5, 0.5, 0.5},		// gray
    {1.0, 0.5, 0.0},		// orange
};

@implementation LLPlotColors

-(void) dealloc;
{
//    long index;
//    
//    for (index = 0; index < [colors count]; index++) {
//        [[colors objectAtIndex:index] release];
//    }
    [colors release];
    [super dealloc];
}

-(id) init {

    if ((self = [super init]) != nil) {
        [self initColorsWithAlpha:1.0];
    }
    return self;
}

-(id)initWithAlpha:(float)alpha {

    if ((self = [super init]) != nil) {
        [self initColorsWithAlpha:alpha];
    }
    return self;
}

-(void)initColorsWithAlpha:(float)alpha {

    long c;
    NSColor *theColor;

    colors = [[NSMutableArray alloc] init];
    for (c = 0; c < sizeof(colorValues) / (sizeof(float) * kGuns); c++) {
        theColor = [NSColor colorWithDeviceRed:colorValues[c][0] green:colorValues[c][1] 
                        blue:colorValues[c][2] alpha:alpha];
        [theColor retain];
        [colors addObject:theColor];  
    }
    [self setNextColorIndex:0];
}

-(NSColor *)nextColor {

    NSColor *theColor;
    
    theColor = [colors objectAtIndex:nextColorIndex];
    if (++nextColorIndex >= [colors count]) {
        nextColorIndex = 0;
    }
    return theColor;
}

-(void) setNextColorIndex:(long)index {

    nextColorIndex = index;
}

@end
