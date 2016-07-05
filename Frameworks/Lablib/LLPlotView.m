//
//  LLPlotView.m
//  Lablib
//
//  Created by John Maunsell on Sun May 04 2003.
//  Copyright (c) 2011. All rights reserved.
//

#import "LLPlotView.h"
#import "LLPlotAxes.h"
#import "LLDistribution.h"
#import "LLViewUtilities.h"

@implementation LLPlotView

- (void)addPlot:(NSArray *)values plotColor:(NSColor *)color;
{
    if (color == nil) {
        color = [defaultColors nextColor];
    }
    [plotValues addObject:values];
    [plotColors addObject:color];
    [enable addObject:[NSNumber numberWithBool:YES]];
    plotPoints = MAX(plotPoints, [values count]);
}

- (void) dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[plotColors release];
	[enable release];
	[plotValues release];
    [scale release];
    [defaultColors release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect;
{
    long index, plot;
    float xAxisMin, xAxisMax, xDrawMin, xDrawMax, yAxisMin, yAxisMax, plotWidth, xOriginForPlot;
	double mean, upperError, lowerError;
    NSArray *values;
    id<LLDistribution> dataPoint;
    NSRect b, b1;
    NSBezierPath *dataPath;
	BOOL noPoints, enabled; 
    float maxY = -FLT_MAX;
    float minY = FLT_MAX;

	// Clear and highlight the bounds

    b = [self bounds];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:b];
    if (highlightPlot) {
        b1 = NSInsetRect(b, 0.5, 0.5);
        b1.origin.x = 0;
        b1.origin.y = 1;
        [[NSColor blackColor] set];
        [NSBezierPath strokeRect:b1];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(b.size.width, b.size.height - 1)
                toPoint:NSMakePoint(b.size.width, 0)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(b.size.width, 0)
                toPoint:NSMakePoint(1, 0)];
    }

// Set up the scaling for the plot.  We plot within a region of the view that leaves a fraction of the plotting
// space (kExtraSpaceFraction) empty on either side.  For drawing the plots, we need to set up a scaling that
// will put all the points (plotPoints) in that space
	
    xAxisMin = (useXDisplayValues) ? xMinDisplayValue : 0;
    xAxisMax = (useXDisplayValues) ? xMaxDisplayValue : MAX(plotPoints - 1, 0);
    yAxisMin = (useYDisplayValues) ? yMinDisplayValue : [scale yMin];
    yAxisMax = (useYDisplayValues) ? yMaxDisplayValue : [scale yMax];
	plotWidth = xAxisMax - xAxisMin;

    [scale setXOrigin:-kXAxisExtraSpace width:plotPoints - 1 + 2 * kXAxisExtraSpace];
	if (plotPoints <= 1) {
		[scale setXOrigin:(xAxisMin - 0.5) width:1.0];
	}
	else {
		[scale setXOrigin:-(plotPoints - 1) * kExtraSpaceFraction
            width:((plotPoints - 1) * (1 + 2 * kExtraSpaceFraction))];
	}

// Draw any highlighted regions on the x or y axes
    
		if ((xHighlight.minValue != xHighlight.maxValue) && (plotPoints > 1)) {
        if (xHighlight.color != nil) {
            [xHighlight.color set];
        }
        else {
            [[NSColor lightGrayColor] set];
        }
        [NSBezierPath fillRect:NSMakeRect([scale scaledX:xHighlight.minValue], 
            [scale scaledY:yAxisMin], 
            [scale scaledXInc:(xHighlight.maxValue - xHighlight.minValue)],
            [self bounds].size.height - bottomMarginPix - topMarginPix)];
    }
    if (yHighlight.minValue != yHighlight.maxValue) {
        if (yHighlight.color != nil) {
            [yHighlight.color set];
        }
        else {
            [[NSColor lightGrayColor] set];
        }
		xDrawMin = (xAxisMin < xAxisMax) ? xAxisMin : [scale xMin] + 0.25 * [scale width];
		xDrawMax = (xAxisMin < xAxisMax) ? plotPoints - 1 : [scale xMax] - 0.25 * [scale width];
        [NSBezierPath fillRect:NSMakeRect([scale scaledX:xDrawMin],
							[scale scaledY:yHighlight.minValue], 
							[scale scaledXInc:(xDrawMax - xDrawMin)], 
							[scale scaledYInc:(yHighlight.maxValue - yHighlight.minValue)])];
    }

// Plot the lines and the error bars

    dataPath = [[[NSBezierPath alloc] init] autorelease];
    for (plot = 0; plot < [plotValues count]; plot++) {		// For each of the lines to plot
		enabled = [[enable objectAtIndex:plot] boolValue];
        values = [plotValues objectAtIndex:plot];
        [(NSColor *)[plotColors objectAtIndex:plot] set];
		noPoints = YES;
        for (index = 0; index < plotPoints && index < [values count]; index++) {
            dataPoint = [values objectAtIndex:index];
			if ([dataPoint n] == 0) {
				continue;
			}
			mean = [dataPoint mean];
			if (isinf(mean)) {
				continue;
			}
			minY = MIN(minY, mean);
			maxY = MAX(maxY, mean);
			upperError = [dataPoint upperError];
			lowerError = [dataPoint lowerError];
			if (noPoints) {
				[dataPath moveToPoint:[scale scaledPoint:NSMakePoint(index, mean)]];
				noPoints = NO;
			}
			else {
				[dataPath lineToPoint:[scale scaledPoint:NSMakePoint(index, mean)]];
			}
			if (isfinite(upperError)) {
				[dataPath moveToPoint:[scale scaledPoint:NSMakePoint(index, upperError)]];
				maxY = MAX(maxY, upperError);
			}
			if (isfinite(lowerError)) {
				[dataPath lineToPoint:[scale scaledPoint:NSMakePoint(index, lowerError)]];
				minY = MIN(minY, lowerError);
			}
            [dataPath moveToPoint:[scale scaledPoint:NSMakePoint(index, mean)]];
			if (enabled) {
				[LLViewUtilities fillCircleAtScaledX:index scaledY:mean withScale:scale radiusPix:3];
			}
        }
		if (noPoints) {
			continue;
		}
		if (enabled) {			// do the rest for maxBin
			[dataPath stroke];
		}
        [dataPath removeAllPoints];
    }
    
// Draw the axes

    [[NSColor blackColor] set];
//    [scale setXOrigin:xAxisMin - xTickSpacing * kXAxisExtraSpace 
//            width:xAxisMax + xTickSpacing * kXAxisExtraSpace - 
//            (xAxisMin - xTickSpacing * kXAxisExtraSpace)];
	if (plotWidth == 0) {
		xOriginForPlot = xAxisMin - 0.5;
		[scale setXOrigin:xOriginForPlot width:1.0];
	}
	else {
		xOriginForPlot = xAxisMin - plotWidth * kExtraSpaceFraction;
		[scale setXOrigin:xOriginForPlot
            width:(plotWidth * (1 + 2 * kExtraSpaceFraction))];
	}

    [LLPlotAxes drawXAxisWithScale:scale from:xAxisMin to:xAxisMax atY:yAxisMin tickSpacing:xTickSpacing
                  tickLabelSpacing:1 tickLabels:xTickLabels label:xAxisLabel];
    [LLPlotAxes drawYAxisWithScale:scale from:yAxisMin to:yAxisMax 
        atX:xOriginForPlot tickSpacing:kMaxMinTicks tickLabelSpacing:2  
		tickLabels:yTickLabels label:yAxisLabel];
//    [LLPlotAxes drawYAxisWithScale:scale from:yAxisMin to:yAxisMax 
//        atX:xAxisMin - xTickSpacing * kXAxisExtraSpace
//         tickSpacing:kMaxMinTicks tickLabelSpacing:2  tickLabels:nil label:yAxisLabel];
        
// Draw the title

	[LLViewUtilities drawString:title 
        centerAndBottomAtPoint:NSMakePoint([scale scaledX:(xAxisMin + xAxisMax) / 2.0],
        [self bounds].size.height - textLineHeightPix) rotation:0.0 withAttributes:nil];

// Annouce our maximum value.  
	if (((minY != FLT_MAX) || (maxY != -FLT_MAX)) && (isfinite(minY) && isfinite(maxY))) {
		if ([scale autoAdjustYMin:minY yMax:maxY object:self]) {
			[self display];
		}
    }
}

- (void)disableAll;
{
	long index;
	
	for (index = 0; index < [enable count]; index++) {
		[enable replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];
	}
	[self setNeedsDisplay:YES];
}

- (void)enableAll;
{
	long index;
	
	for (index = 0; index < [enable count]; index++) {
		[enable replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:YES]];
	}
	[self setNeedsDisplay:YES];
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

- (void)initializeWithScale:(LLViewScale *)plotScale;
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
	[scale setAutoAdjustYMin:NO];
	yTickSpacing = kMaxMinTicks;
    plotColors = [[NSMutableArray alloc] init];
    plotValues = [[NSMutableArray alloc] init];
    enable = [[NSMutableArray alloc] init];
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
	long index, numEnabled, firstIndex;
	
	if ([enable count] < 2) {
		return;
	}
	if ([theEvent clickCount] > 1) {
		[self enableAll];
	}
	else {
		for (index = numEnabled = 0, firstIndex = -1; index < [enable count]; index++) {
			if ([[enable objectAtIndex:index] boolValue]) {
				firstIndex = (firstIndex < 0) ? index : firstIndex;
				if (++numEnabled > 1) {
					break;
				}
			}
		}
		[self disableAll];
		if (numEnabled > 1) {
			[enable replaceObjectAtIndex:0 withObject:[NSNumber numberWithBool:YES]];
		}
		else {
			[enable replaceObjectAtIndex:((firstIndex + 1) % [enable count])
									withObject:[NSNumber numberWithBool:YES]];
		}
	}
	[self setNeedsDisplay:YES];
}

- (long)points;
{
    return plotPoints;
}

- (LLViewScale *)scale;
{
    return scale;
}

- (void)setColor:(NSColor *)newColor forPlot:(long)plotIndex;
{
	if (plotIndex < [plotColors count]) {
		[plotColors replaceObjectAtIndex:plotIndex withObject:newColor];
	}
}
	
- (void)setPoints:(long)pointsToPlot;
{
    plotPoints = pointsToPlot;
}

- (void) setScale:(LLViewScale *)newScale {

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
    [scale setViewRectForScale:NSMakeRect(leftMarginPix, bottomMarginPix, 
                    plotWidthPix, plotHeightPix)];
}

- (void)setTitle:(NSString *)string {

    [string retain];
    [title release];
    title = string;
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
 
- (void)setXMin:(float)xMin xMax:(float)xMax;
{
    xMaxDisplayValue = xMax;
    xMinDisplayValue = xMin;
    useXDisplayValues = YES;						
}

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

- (void) setYMin:(float)yMin yMax:(float)yMax {

    yMaxDisplayValue = yMax;
    yMinDisplayValue = yMin;
    useYDisplayValues = YES;						
}

- (float)xMaxDisplayValue;
{
    return xMaxDisplayValue;
}

- (float)xMinDisplayValue;
{
    return xMinDisplayValue;
}

@end
