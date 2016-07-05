//
//  LLHeatMapView.m
//  Lablib
//
//  Created by John Maunsell on September 15, 2012.
//  Copyright (c) 2012. All rights reserved.
//

#import "LLHeatMapView.h"
#import "LLPlotAxes.h"
#import "LLDistribution.h"
#import "LLNormDist.h"
#import "LLViewUtilities.h"

@implementation LLHeatMapView

@synthesize plotValues;
@synthesize plotXPoints;
@synthesize plotYPoints;
@synthesize title;
@synthesize xMaxValue;
@synthesize xMinValue;
@synthesize yMaxValue;
@synthesize yMinValue;

- (void) dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[plotColors release];
	[plotValues release];
    [scale release];
    [defaultColors release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect;
{
    long aziIndex, eleIndex, minN;
    float xAxisMin, xAxisMax, yAxisMin, yAxisMax, xOriginForPlot, yOriginForPlot, minValue, maxValue;
    float fraction, meanValue, redColor, greenColor, blueColor;
    NSRect b, cellRect;
    NSArray *elevationValues;
    LLNormDist *dist;
    
    // If we're uninitialized, don't do anything
    
    if (plotXPoints == 0 && plotYPoints == 0) {
        return;
    }

	// Clear and highlight the bounds

    b = [self bounds];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:b];
    
// Set up the scaling for the plot.  We plot within a region of the view that leaves a fraction of the plotting
// space (kExtraSpaceFraction) empty on either side.  For drawing the plots, we need to set up a scaling that
// will put all the points (plotXPoints and plotYPoints) in that space
	
    xAxisMin = (xMinValue != xMaxValue) ? xMinValue : 0;
    xAxisMax = (xMinValue != xMaxValue) ? xMaxValue : MAX(plotXPoints - 1, 0);
    yAxisMin = (yMinValue != yMaxValue) ? yMinValue : [scale yMin];
    yAxisMax = (yMinValue != yMaxValue) ? yMaxValue : [scale yMax];
    [scale setXOrigin:-(plotXPoints) * kExtraSpaceFraction
                width:((plotXPoints) * (1 + 2 * kExtraSpaceFraction))];
		[scale setYOrigin:-(plotYPoints) * kExtraSpaceFraction
                    height:((plotYPoints) * (1 + 2 * kExtraSpaceFraction))];

// Plot heat map

    minN = LONG_MAX;
    minValue = FLT_MAX;
    maxValue = FLT_MIN;
    for (aziIndex = 0; aziIndex < plotXPoints; aziIndex++) {
        elevationValues = [plotValues objectAtIndex:aziIndex];
        for (eleIndex = 0; eleIndex < plotYPoints; eleIndex++) {
            dist = [elevationValues objectAtIndex:eleIndex];
            minN = MIN(minN, [dist n]);
            if ([dist n] == 0) {
                continue;
            }
            meanValue = [dist mean];
            maxValue = MAX(maxValue, meanValue);
            minValue = MIN(minValue, meanValue);
        }
    }
    [[NSColor blackColor] set];
    cellRect = NSMakeRect(1.0, 1.0, [scale scaledXInc:1.025], [scale scaledYInc:1.025]);
    for (aziIndex = 0; aziIndex < plotXPoints; aziIndex++) {
        cellRect.origin.x = [scale scaledX:aziIndex] - 0.5;
        elevationValues = [plotValues objectAtIndex:aziIndex];
        for (eleIndex = 0; eleIndex < plotYPoints; eleIndex++) {
            dist = [elevationValues objectAtIndex:eleIndex];
            if ([dist n] == 0) {
                continue;
            }
            meanValue = [dist mean];
            if (maxValue == minValue) {
                fraction = 0.5;
            }
            else {
                fraction = (meanValue - minValue) / (maxValue - minValue);
            }
            redColor = (fraction > 0.4) ? 1.0 : fraction / 0.4;
            blueColor = (fraction < 0.8) ? 0.0 : ((fraction - 0.8) / 0.2);            
            greenColor = (fraction > 0.8) ? 1.0 : ((fraction < 0.4) ? 0.0 : (fraction - 0.4) / 0.4);
            [[NSColor colorWithCalibratedRed:redColor green:greenColor blue:blueColor alpha:1.0] set];
            cellRect.origin.y = [scale scaledY:eleIndex] - 0.5;
            [NSBezierPath fillRect:cellRect];
        }
    }

// Draw the axes

    [[NSColor blackColor] set];
    xOriginForPlot = -(plotXPoints) * kExtraSpaceFraction - 0.5;
    [scale setXOrigin:xOriginForPlot width:((plotXPoints) * (1 + 2 * kExtraSpaceFraction))];
    yOriginForPlot = -(plotYPoints) * kExtraSpaceFraction - 0.5;
    [scale setYOrigin:yOriginForPlot height:((plotYPoints) * (1 + 2 * kExtraSpaceFraction))];
    [LLPlotAxes drawXAxisWithScale:scale from:xAxisMin to:xAxisMax atY:yOriginForPlot tickSpacing:xTickSpacing
                  tickLabelSpacing:1 tickLabels:xTickLabels label:xAxisLabel];
    [LLPlotAxes drawYAxisWithScale:scale from:yAxisMin to:yAxisMax atX:xOriginForPlot tickSpacing:yTickSpacing
                  tickLabelSpacing:1 tickLabels:yTickLabels label:yAxisLabel];
        
// Draw the title

	[LLViewUtilities drawString:title 
        centerAndBottomAtPoint:NSMakePoint([scale scaledX:(xAxisMin + xAxisMax) / 2.0],
        [self bounds].size.height - textLineHeightPix) rotation:0.0 withAttributes:nil];
}

// Handler for change in y max or min on scaling

- (void) handleScaleChange:(NSNotification *)note {

    [self setNeedsDisplay:YES];
}

- (id) initWithFrame:(NSRect)frame;
{
    if ( self = [super initWithFrame:frame]) {
        [self initializeWithScale:nil];
    }
    return self;
}

- (id) initWithFrame:(NSRect)frame scaling:(LLViewScale *)plotScale;
{    
    if (self = [super initWithFrame:frame]) {
        [self initializeWithScale:plotScale];
    }
    return self;
}

- (void) initializeWithScale:(LLViewScale *)plotScale;
{
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
        
    textLineHeightPix = [layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]];
    if (plotScale == nil) {
        plotScale = [[[LLViewScale alloc] init] autorelease];
    }
    [self setScale:plotScale];
    defaultColors = [[LLPlotColors alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChange:)
            name:@"LLYScaleChanged" object:scale];
    xTickSpacing = 1.0;
	yTickSpacing = 1.0;
	[scale setAutoAdjustYMin:NO];
    plotColors = [[NSMutableArray alloc] init];
    plotValues = [[NSMutableArray alloc] init];
}

// Overwrite isOpaque to improve performance

- (BOOL)isOpaque;
{
	return YES;
}

// For a double click, enable all plots.  Otherwise, if more than one plot is active, make
// only the first plot active.  If only one is active, make the next active.

- (void)mouseDown:(NSEvent *)theEvent;
{
    
    // ??? Eventually we'll want this to toggle between min-max and zero-max plotting
	[self setNeedsDisplay:YES];
}

- (LLViewScale *)scale;
{
    return scale;
}

- (void)setScale:(LLViewScale *)newScale {

    float plotHeightPix, plotWidthPix;
    NSRect b;
    
    [newScale retain];
    if (scale != nil) {
        [scale release];
    }
    scale = newScale;
    b = [self bounds];
    plotWidthPix = b.size.width - leftMarginPix - kRightMarginPix;
    plotHeightPix = b.size.height - bottomMarginPix - topMarginPix;
    [scale setViewRectForScale:NSMakeRect(leftMarginPix, bottomMarginPix, plotWidthPix, plotHeightPix)];
}

- (void)setHighlightPlot:(BOOL)state {

    if (highlightPlot != state) {
        highlightPlot = state;
        [self setNeedsDisplay:YES];
    }
}

- (void)setHighlightXRangeFrom:(float)minValue to:(float)maxValue {

    xHighlight.minValue = minValue;
    xHighlight.maxValue = maxValue;
    [self setNeedsDisplay:YES];
}

- (void)setHighlightXRangeColor:(NSColor *)color{

    [color retain];
    if (xHighlight.color != nil) {
        [xHighlight.color release];
    }
    xHighlight.color = color;
    [self setNeedsDisplay:YES];
}

- (void)setHighlightYRangeFrom:(float)minValue to:(float)maxValue {

    yHighlight.minValue = minValue;
    yHighlight.maxValue = maxValue;
    [self setNeedsDisplay:YES];
}

- (void) setHighlightYRangeColor:(NSColor *)color{

    [color retain];
    if (yHighlight.color != nil) {
        [yHighlight.color release];
    }
    yHighlight.color = color;
    [self setNeedsDisplay:YES];
}

- (void) setXAxisLabel:(NSString *)label {

    [label retain];
    [xAxisLabel release];
    xAxisLabel = label;
}

- (void)setXAxisTickSpacing:(float)spacing {

    xTickSpacing = spacing;
}

- (void) setXAxisTickLabels:(NSArray *)newArray {

    [newArray retain];
    [xTickLabels release];
    xTickLabels = newArray;
}

// Define the values that will be put onto the axis tick marks
// The plot will always be plotted over its full range, this affects
// only what appears as labels on the axis
 
- (void) setYAxisLabel:(NSString *)label {

    [label retain];
    [yAxisLabel release];
    yAxisLabel = label;
}

- (void) setYAxisTickSpacing:(float)spacing {

    yTickSpacing = spacing;
}

- (void)setYAxisTickLabels:(NSArray *)newArray;
{
    [newArray retain];
    [yTickLabels release];
    yTickLabels = newArray;
}


@end
