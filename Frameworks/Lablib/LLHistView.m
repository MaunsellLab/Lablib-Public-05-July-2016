//
//  LLHistView.m
//  Lablib
//
//  Copyright (c) 2006. All rights reserved.
//

#import "LLHistView.h"
#import "LLPlotAxes.h"
#import "LLViewUtilities.h"

@implementation LLHistView

- (void)clearAllFills {

    long index;
    XHistAxisMark mark;
    
    for (index = 0; index < [marks count]; index++) {
        [[marks objectAtIndex:index] getValue:&mark];
        [mark.color release];
    }
    [marks removeAllObjects];
}

- (void) dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [marks release];
    [scale release];
    [yUnitArray release];
    [colorArray release];
    [dataArray release];
    [enableArray release];
    [super dealloc];
}

- (void) drawRect:(NSRect)rect {

    long index, hist, bin;
    float xAxisMin, xAxisMax, yAxisMin, yAxisMax, yOriginPix;
    float binSum;
    double yUnit, *pData;
    XHistAxisMark mark;
    NSRect b, b1;
    NSBezierPath *dataPath;  

    if (hidden) {				 // do nothing if the window is not on scren
        return;
    }
    xAxisMin = (useXDisplayValues) ? xMinDisplayValue : 0;
    xAxisMax = (useXDisplayValues) ? xMaxDisplayValue : dataLength;
    yAxisMin = (useYDisplayValues) ? yMinDisplayValue : 0;
    yAxisMax = (useYDisplayValues) ? yMaxDisplayValue : [scale yMax];

// Clear and highlight the bounds

    b = [self bounds];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:b];

    if (highlight) {
        b1 = NSInsetRect(b, 2, 2);
        [[NSColor blackColor] set];
        [NSBezierPath strokeRect:b1];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(b.size.width - 2, b.size.height - 2)
                toPoint:NSMakePoint(b.size.width - 2, 2)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(b.size.width - 2, 2)
                toPoint:NSMakePoint(2, 2)];
    }

// Draw any marked regions
    
    [scale setXOrigin:xAxisMin width:xAxisMax - xAxisMin];
    for (index = 0; index < [marks count]; index++) {
        [[marks objectAtIndex:index] getValue:&mark];
        yOriginPix = [scale scaledY:0] + ((mark.yPix < 0) ? mark.yPix : 0);
        [mark.color set];
        [NSBezierPath fillRect:NSMakeRect([scale scaledX:MAX(mark.xMin, xAxisMin)], 
            yOriginPix, 
            [scale scaledXInc:MIN((mark.xMax - mark.xMin), xAxisMax)],
            labs(mark.yPix))];
    }

// Draw the histogram

    [scale setXOrigin:0 width:plotBins];
    dataPath = [[NSBezierPath alloc] init];
	maxBin = 0;
	for (hist = 0; hist < [dataArray count]; hist++) {
		[dataPath moveToPoint:[scale scaledPoint:NSMakePoint(0, 0)]];
		binSum = bin = 0.0;
		pData = [[dataArray objectAtIndex:hist] pointerValue];
		yUnit = [[yUnitArray objectAtIndex:hist] doubleValue];
		for (index = 0; index < dataLength; index++, pData++) {
			binSum += *pData;
			if (index + 1 == (bin + 1) * dataLength / plotBins) {
				binSum = binSum * yUnit / ((sumWhenBinning) ? 1.0 : (dataLength / plotBins));
				[dataPath lineToPoint:[scale scaledPoint:NSMakePoint(bin, binSum)]];
				[dataPath lineToPoint:[scale scaledPoint:NSMakePoint(++bin, binSum)]];
				maxBin = MAX(maxBin, binSum);
				binSum = 0.0;
			}
		}
		[dataPath lineToPoint:[scale scaledPoint:NSMakePoint(bin, 0)]];
		[dataPath closePath];
		[(NSColor *)[colorArray objectAtIndex:hist] set]; 
		if ([[enableArray objectAtIndex:hist] boolValue]) {			// do the rest for maxBin
			[dataPath fill];
		}
		[dataPath removeAllPoints];
	}
    [dataPath release];

// Draw the axes

    [[NSColor blackColor] set];
    [scale setXOrigin:xAxisMin width:xAxisMax - xAxisMin];
    [LLPlotAxes drawXAxisWithScale:scale from:xAxisMin to:xAxisMax 
        atY:yAxisMin tickSpacing:xTickSpacing tickLabelSpacing:xTickLabelSpacing 
        tickLabels:nil label:xAxisLabel];

    [LLPlotAxes drawYAxisWithScale:scale from:yAxisMin to:yAxisMax 
        atX:xAxisMin tickSpacing:yAxisMax tickLabelSpacing:1 tickLabels:nil label:yAxisLabel];
        
// Draw the title

	[LLViewUtilities drawString:title 
        centerAndBottomAtPoint:NSMakePoint([scale scaledX:(xAxisMin + xAxisMax) / 2.0],
        [self bounds].size.height - textLineHeightPix - 3) rotation:0.0 withAttributes:nil];

// Announce our maximum value.  

    if (autoBinWidth && (maxBin > plotBins) && (plotBins < dataLength)) {
        plotBins = MIN(plotBins * 2, dataLength);
        [self display];
    }
    if ([scale autoAdjustYMin:0.0 yMax:maxBin object:self]) {
        [self display];
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"LLHistView (%lx) hidden: %d dataLength: %ld",
            (unsigned long)&self, hidden, dataLength];
}

- (void)disableAll;
{
	long index;
	
	for (index = 0; index < [enableArray count]; index++) {
		[enableArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];
	}
	[self setNeedsDisplay:YES];
}

- (void)enableAll;
{
	long index;
	
	for (index = 0; index < [enableArray count]; index++) {
		[enableArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:YES]];
	}
	[self setNeedsDisplay:YES];
}

- (void) fillXAxisFrom:(float)xMin to:(float)xMax heightPix:(long)heightPix color:(NSColor *)color  {

    XHistAxisMark mark;

    mark.xMin = xMin;
    mark.xMax = xMax;
    mark.yPix = -heightPix;
    mark.color = color;
    [color retain];
    [marks addObject:[NSValue value:&mark withObjCType:@encode(XHistAxisMark)]];
}

- (void) fillXFrom:(float)xMin to:(float)xMax color:(NSColor *)color {

    XHistAxisMark mark;

    mark.xMin = xMin;
    mark.xMax = xMax;
    mark.yPix = [self bounds].size.height - bottomMarginPix - topMarginPix;
    mark.color = color;
    [color retain];
    [marks addObject:[NSValue value:&mark withObjCType:@encode(XHistAxisMark)]];
}

- (void) handleScaleChange:(NSNotification *)note;
{
	if (!hidden) {
		[self setNeedsDisplay:YES];
	}
}

- (void) hide:(BOOL)state {

    hidden = state;
}

- (void) initializeHistView;
{
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    textLineHeightPix = [layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]];
	
	yUnitArray = [[NSMutableArray alloc] init];
	colorArray = [[NSMutableArray alloc] init];
	dataArray = [[NSMutableArray alloc] init];
	enableArray = [[NSMutableArray alloc] init];
    [self setPlotBins:kDefaultBins];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(handleScaleChange:)
            name:@"LLYScaleChanged" object:scale];
    autoBinWidth = sumWhenBinning = YES;
    xTickSpacing = [scale xMax];
	xTickLabelSpacing = 1.0;
	[scale setAutoAdjustYMin:NO];
	marks = [[NSMutableArray alloc] init];
}

- (id)initWithFrame:(NSRect)frame;
{
    if ((self = [super initWithFrame:frame]) != nil) {
		[self setScale:[[[LLViewScale alloc] init] autorelease]];
        [self initializeHistView];
    }
    return self;
}

- (id) initWithFrame:(NSRect)frame scaling:(LLViewScale *)plotScale;
{
    if ((self = [super initWithFrame:frame]) != nil) {
		[self setScale:plotScale];
        [self initializeHistView];
    }
    return self;
}

- (BOOL)isOpaque;							// Overwrite isOpaque to improve performance
{
	return YES;
}

// For a double click, enable all plots.  Otherwise, if more than one plot is active, make
// only the first plot active.  If only one is active, make the next active.

- (void)mouseDown:(NSEvent *)theEvent;
{
	long index, numEnabled, firstIndex;
	
	if ([enableArray count] < 2) {
		return;
	}
	if ([theEvent clickCount] > 1) {
		[self enableAll];
	}
	else {
		for (index = numEnabled = 0, firstIndex = -1; index < [enableArray count]; index++) {
			if ([[enableArray objectAtIndex:index] boolValue]) {
				firstIndex = (firstIndex < 0) ? index : firstIndex;
				if (++numEnabled > 1) {
					break;
				}
			}
		}
		[self disableAll];
		if (numEnabled > 1) {
			[enableArray replaceObjectAtIndex:0 withObject:[NSNumber numberWithBool:YES]];
		}
		else {
			[enableArray replaceObjectAtIndex:((firstIndex + 1) % [enableArray count])
									withObject:[NSNumber numberWithBool:YES]];
		}
	}
	[self setNeedsDisplay:YES];
}

- (void) setAutoBinWidth:(BOOL)state {

    autoBinWidth = state;
}

- (void) setPlotBins:(long)binsToPlot {

    plotBins = binsToPlot;
}

- (void)setData:(double *)histData length:(long)histLength color:(NSColor *)color {

	[dataArray addObject:[NSValue valueWithPointer:histData]];
	[yUnitArray addObject:[NSNumber numberWithDouble:[scale yMax]]];
	[enableArray addObject:[NSNumber numberWithBool:YES]];
    [self setDataLength:histLength];
    if (color != nil) {
		[colorArray addObject:color];
    }
    else {
        [colorArray addObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.8]];
    }
}

- (void)setData:(double *)histData length:(long)histLength color:(NSColor *)color yUnit:(double)histUnit
{
	[dataArray addObject:[NSValue valueWithPointer:histData]];
	[yUnitArray addObject:[NSNumber numberWithDouble:histUnit]];
	[enableArray addObject:[NSNumber numberWithBool:YES]];
    [self setDataLength:histLength];
    if (color != nil) {
		[colorArray addObject:color];
    }
    else {
        [colorArray addObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.8]];
    }
}

- (void) setDataLength:(long)length {

    dataLength = length;
}

// Define the values that will be put onto the tick labels
 
- (void) setDisplayXMin:(float)xMin xMax:(float)xMax {

    xMaxDisplayValue = xMax;
    xMinDisplayValue = xMin;
    useXDisplayValues = YES;						
}

- (void) setDisplayYMin:(float)yMin yMax:(float)yMax{

    yMaxDisplayValue = yMax;
    yMinDisplayValue = yMin;
    useYDisplayValues = YES;						
}

- (void)setScale:(LLViewScale *)newScale {

    float plotHeightPix, plotWidthPix;
    NSRect b;
    
    [newScale retain];
	[scale release];
    scale = newScale;

    b = [self bounds];
    plotWidthPix = b.size.width - leftMarginPix - kRightMarginPix;
    plotHeightPix = b.size.height - bottomMarginPix - topMarginPix;
    [scale setViewRectForScale:NSMakeRect(leftMarginPix, bottomMarginPix, 
                    plotWidthPix, plotHeightPix)];
}

- (void) setSumWhenBinning:(BOOL)state {

    sumWhenBinning = state;
}

- (void) setTitle:(NSString *)string {

    [string retain];
    [title release];
    title = string;
}

- (void) setHighlightHist:(BOOL)state {

    if (highlight != state) {
        highlight = state;
        [self setNeedsDisplay:YES];
    }
}

- (void) setXAxisLabel:(NSString *)label;
{
    [label retain];
    [xAxisLabel release];
    xAxisLabel = label;
}

- (void) setXAxisTickLabelSpacing:(float)spacing;
{
    xTickLabelSpacing = spacing;
}

- (void) setXAxisTickSpacing:(float)spacing;
{
    xTickSpacing = spacing;
}

- (void) setYAxisLabel:(NSString *)label;
{
    [label retain];
    [yAxisLabel release];
    yAxisLabel = label;
}

// Specify the value that will be assigned to each unit in a bin.  For example,
// in a 1ms histogram, each unit might correspond to 1000 s/s.  

- (void) setYUnit:(double)unitValue;
{
	long index;
	 NSNumber *yUnit = [NSNumber numberWithDouble:unitValue];
	
	for (index = 0; index < [yUnitArray count]; index++) {
		[yUnitArray replaceObjectAtIndex:index withObject:yUnit];
	}
}

- (void) setYUnit:(double)unitValue index:(long)index;
{
	[yUnitArray replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble:unitValue]];
}

@end
