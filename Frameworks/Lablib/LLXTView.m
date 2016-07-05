//
//  LLXTView.m
//  Lablib
//
// This is the master view that contains all the individual plots.  
// It's job is to dispatch event to the other plots.  The only
// drawing that it does itself is putting up the time axis

//  Created by John Maunsell on Wed May 21 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTView.h"
#import "LLPlotAxes.h"
#import "LLViewUtilities.h"

#define kBaseWidthPix			(kEyePlotsOriginPix + kEyeColWidthPix + kGapPix)
#define kDefaultDurS			5.0
#define kDefaultFactor			0.25
#define kGapPix                         10
#define kMajorBright			0.85
#define kMinorBright			0.95
#define kPixPerS                        100
#define kTickHeightPix			5

#define kAxisOriginPix			(kGapPix)
#define kAxisWidthPix			15
#define kAxisColWidthPix		kAxisWidthPix

#define kEventPlotOriginPix		(kAxisOriginPix + kAxisColWidthPix)
#define kEventPlotWidthPix		80
#define kEventColWidthPix		(kEventPlotWidthPix + kGapPix)

#define kStimPlotOriginPix		(kEventPlotOriginPix + kEventColWidthPix)
#define kStimPlotWidthPix		15
#define kStimColWidthPix		(kStimPlotWidthPix + kGapPix)

#define kSpikePlotOriginPix		(kStimPlotOriginPix + kStimColWidthPix)
#define kSpikePlotWidthPix		15
#define kSpikeColWidthPix		(kSpikePlots * (kSpikePlotWidthPix + kGapPix))

#define kEyePlotsOriginPix		(kSpikePlotOriginPix + kSpikeColWidthPix)
#define kEyePlotWidthPix		80
#define kEyePlotOrigin(x)		(kEyePlotsOriginPix + x * (kEyePlotWidthPix + kGapPix))
#define kEyeColWidthPix			(kEyePlots * (kEyePlotWidthPix + kGapPix))

@implementation LLXTView

- (void)checkScroll:(NSTimer *)timer {

    float scrollDist, scrollOrigin;
    NSRect drawRect, scrollRect;

    [self displayIfNeeded];
    return;
    
    if (lastEventTimeMS > lastScrollTimeMS) {
        drawRect = scrollRect = [self visibleRect];
        scrollDist = MIN(scrollRect.size.height, 
                        [scale scaledYInc:lastEventTimeMS - lastScrollTimeMS]);
        if (scrollDist < scrollRect.size.height) {
            scrollOrigin = MAX(0, [scale scaledYInc:lastScrollTimeMS - lastTimePlottedMS]);
            scrollRect.origin.y = scrollOrigin;
            scrollRect.size.height -= scrollOrigin;
            [[NSGraphicsContext currentContext] saveGraphicsState];
            [[NSBezierPath bezierPathWithRect:[self visibleRect]] setClip];
            [self scrollRect:scrollRect by:NSMakeSize(0, -scrollDist)];
            [[NSGraphicsContext currentContext] restoreGraphicsState]; // restore clipRect
            drawRect.origin.y = drawRect.size.height - scrollDist;
            drawRect.size.height = scrollOrigin;
        }
        lastScrollTimeMS = lastEventTimeMS;
        [self setNeedsDisplayInRect:drawRect];
    }
}

- (void)dealloc;
{
	unsigned long index;

    [timer invalidate];
    [timer release];
    [majorGridColor release];
    [minorGridColor release];
    [scale release];
    [xtPlots release];
	for (index = 0; index < kEyePlots; index++) {
		[eyePlots[index] release];
	}
   [super dealloc];
}

- (void)drawRect:(NSRect)rect {

    long index;
    float factor, yStart, yStop, x, y;
    TickSettings ticks;
	
    NSEraseRect(rect);
	if (lastEventTimeMS == 0) {
        return;
    }
    
// Draw the time axis

	[scale setViewRectForScale:NSMakeRect(kAxisOriginPix, 0,  kAxisWidthPix,
            [self bounds].size.height)];
    yStart = (lastEventTimeMS - durationMS) / 1000.0;
    yStop = lastEventTimeMS / 1000.0;
	[scale setScaleRect:NSMakeRect(0.0, yStart, 1.0, durationMS / 1000.0)];
	[LLPlotAxes getTickLimits:&ticks spacing:1.0 fromValue:yStart toValue:yStop];
    ticks.low--;
    ticks.high++;
	[minorGridColor set];
    for (index = ticks.low * 10; index <= ticks.high * 10; index++) {
        if ((index % 10) == 0) {
           [majorGridColor set];
            x = [scale scaledX:1.0];
            y = [scale scaledY:index / 10.0];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y)
                toPoint:NSMakePoint(NSMaxX([self bounds]) - kGapPix, y)];
            [[NSColor blackColor] set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                toPoint:NSMakePoint(x - kTickHeightPix, y)];
            [LLViewUtilities 
                drawString:[NSString stringWithFormat:@"%ld", (long)(index / 10.0) % 100] 
                rightAndCenterAtPoint:NSMakePoint(x - kTickHeightPix, y) 
                rotation:0.0 withAttributes:nil];
            [minorGridColor set];				// restore for the (many) minor lines
        }
        else {
            [NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(1.0, index / 10.0)] 
                toPoint:NSMakePoint(NSMaxX([self bounds]) - kGapPix, [scale scaledY:index / 10.0])];
       }
       [NSBezierPath strokeLineFromPoint:[scale scaledPoint:NSMakePoint(1.0, index / 10.0)] 
            toPoint:NSMakePoint(NSMaxX([self bounds]) - kGapPix, [scale scaledY:index / 10.0])];
    }
    [[NSColor blackColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint([scale scaledX:1.0], 0) 
            toPoint:NSMakePoint([scale scaledX:1.0], [self bounds].size.height)];

// Draw the eye time plots.  Before calling the eyePlots, set the clipping so that eye traces are
// restricted to the portion or our view that contains eyePlots

    if (eyeWindowWidth > 0) {
        factor = 1.0 / eyeWindowWidthFactor;
        [scale setScaleRect:NSMakeRect(eyeWindowOrigin + eyeWindowWidth * (0.5 - factor / 2.0),
                    lastEventTimeMS - durationMS, eyeWindowWidth * factor, durationMS)];
    }
    else {
        [scale setScaleRect:NSMakeRect(SHRT_MIN, lastEventTimeMS - durationMS, USHRT_MAX, durationMS)];
    }
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [NSBezierPath clipRect:NSMakeRect(kEyePlotsOriginPix, 0, kEyeColWidthPix, [self bounds].size.height)];
    for (index = 0; index < kEyePlots; index++) {
        [scale setViewRectForScale:NSMakeRect(kEyePlotOrigin(index), 0, 
                    kEyePlotWidthPix,  [self bounds].size.height)];
        [eyePlots[index] drawWindow];
    }
    for (index = 0; index < kEyePlots; index++) {
        [scale setViewRectForScale:NSMakeRect(kEyePlotOrigin(index), 0, 
                    kEyePlotWidthPix,  [self bounds].size.height)];
        [eyePlots[index] drawEye];
    }
    [[NSGraphicsContext currentContext] restoreGraphicsState];

// Do the event plot

	[scale setViewRectForScale:NSMakeRect(kEventPlotOriginPix, 0,  kEventPlotWidthPix,
                [self bounds].size.height)];
	[scale setScaleRect:NSMakeRect(0.0, lastEventTimeMS - durationMS, 1.0, durationMS)];
    [eventPlot draw];
    
// Do the stim plot

	[scale setViewRectForScale:NSMakeRect(kStimPlotOriginPix, 0,  kStimPlotWidthPix,
                [self bounds].size.height)];
    [stimPlot draw];
    
// Do the spike plots

	[scale setViewRectForScale:NSMakeRect(kSpikePlotOriginPix, 0,  kSpikePlotWidthPix,
                [self bounds].size.height)];
    for (index = 0; index < kSpikePlots; index++) {
        [spikePlots[index] draw];
    }
   
// Record the time value corresponding to the top of the plot

//    lastTimePlottedMS = lastEventTimeMS;
//	NSLog(@"LLXYView drawRect: interval %.0f    duration %.0f", 
//		(startTimeS - lastTimeS) * 1000.0, ([LLSystemUtil getTimeS] - startTimeS) * 1000.0);
//	lastTimeS = startTimeS;
}

- (void)eventName:(NSString *)name eventTime:(NSNumber *)time {

    [eventPlot addEvent:name time:[NSNumber numberWithLong:[time longValue] - timeOffsetMS]];
	[self updateEventTime:[time longValue] - timeOffsetMS];
}

- (void)eyeRect:(NSRect)rect time:(long)time;
{
    eyeWindowOrigin = rect.origin.x;
    eyeWindowWidth = rect.size.width;
//    time -= timeOffsetMS;
    if (kEyePlots > 0) {
        [eyePlots[0] setEyeWindowOrigin:rect.origin.x width:rect.size.width];
		if (kEyePlots > 1) {
			[eyePlots[1] setEyeWindowOrigin:rect.origin.y width:rect.size.height];
		}
    }
}

- (void)eyeWindowWidthFactor:(float)factor {

    eyeWindowWidthFactor = MAX(0.01, factor);
}

- (id)initWithFrame:(NSRect)frame {

    long index;
    float eyeColors[kEyePlots][4] = {
        {0.5, 0.0, 0.25, 1.0},
        {0.5, 0.5, 0.0, 1.0}
        };
    
    self = [super initWithFrame:frame];
    if (self) {
        [[[self enclosingScrollView] contentView] setDrawsBackground:NO];
        
        [self setDurationS:kDefaultDurS];
        eyeWindowWidthFactor = kDefaultFactor;
        scale = [[LLViewScale alloc] init];
        majorGridColor = [[NSColor colorWithDeviceRed:kMajorBright green:kMajorBright 
                        blue:kMajorBright alpha:1.0] retain];
        minorGridColor = [[NSColor colorWithDeviceRed:kMinorBright green:kMinorBright 
                        blue:kMinorBright alpha:1.0] retain];

        xtPlots = [[NSMutableArray alloc] init];

// Add the eye plots
        
        for (index = 0; index < kEyePlots; index++) {
            eyePlots[index] = [[LLXTEyePlot alloc] init];
            [xtPlots addObject:eyePlots[index]];
            [eyePlots[index] setLineColor:[NSColor colorWithDeviceRed:eyeColors[index][0]
                green:eyeColors[index][1] blue:eyeColors[index][2] alpha:eyeColors[index][3]]];
        }
        
// Add the event plot

        eventPlot = [[LLXTEventPlot alloc] init];
        [xtPlots addObject:eventPlot];

// Add the stim plot

        stimPlot = [[LLXTStimPlot alloc] init];
        [xtPlots addObject:stimPlot];

// Add the spike plots

        for (index = 0; index < kSpikePlots; index++) {
            spikePlots[index] = [[LLXTSpikePlot alloc] init];
            [xtPlots addObject:spikePlots[index]];
            [spikePlots[index] release];
        }

// Initialize all the plots

        [xtPlots makeObjectsPerformSelector:@selector(setScale:) withObject:scale];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.050 target:self
                selector:@selector(checkScroll:) userInfo:nil repeats:YES];
        [timer retain];
    }
    return self;
}

// Overwrite isOpaque to improve performance

- (BOOL)isOpaque;
{
	return YES;
}

// The offset time is critical for good displays.  All graphics points are represented by floats,
// which actually have fewer mantissa bits than do longs.  If we have large base times (>100M), there
// is appreciable rounding of points.  We use timeOffsetMS to keep the mantissas of the times we
// use small

- (void)reset:(long)resetTimeMS {

    timeOffsetMS = resetTimeMS;
    lastTimePlottedMS = lastScrollTimeMS = lastEventTimeMS = 0;
    [xtPlots makeObjectsPerformSelector:@selector(clear)];
}

- (void)sampleChannel:(short)channel value:(short)value;
{
    float sampleTimeMS;
    
    if (channel < kEyePlots && sampleBaseTimeMS > 0) {
        sampleTimeMS = sampleBaseTimeMS + sampleCount[channel] * samplePeriodMS;
        [eyePlots[channel] addPoint:NSMakePoint(value, sampleTimeMS)];
        sampleCount[channel]++;
        [self updateEventTime:sampleTimeMS];
   }
}

- (void) sampleZeroTimeMS:(long)zeroTimeMS {

    long index;
    
    sampleBaseTimeMS = lastEventTimeMS = zeroTimeMS - timeOffsetMS;
    for (index = 0; index < kEyePlots; index++) {
        sampleCount[index] = 0;
    }
}

- (void)setDurationS:(double)dur {

    durationMS = dur * 1000.0;
    [self setFrameSize];
    [scale setHeight:durationMS];
	[scale setViewRectForScale:NSMakeRect(0, 0, 1, [self bounds].size.height)];
	[xtPlots makeObjectsPerformSelector:@selector(setDurationS:) 
                                withObject:[NSNumber numberWithFloat:dur]];
}

- (void)setFrameSize {

    NSRect frameRect;
    
    frameRect = [self frame];
    frameRect.size.width = [self sizePix].width;
    frameRect.size.height = durationMS / 1000.0 * kPixPerS;
    [self setFrame:frameRect];
}

- (void)setSamplePeriodMS:(float)samplePerMS;
{
    samplePeriodMS = samplePerMS;
}

- (void)setSamplePeriodMS:(float)samplePerMS spikeChannels:(short)spikes spikeTickPerMS:(long)ticksPerMS;
{
    samplePeriodMS = samplePerMS;
    spikeChannels = spikes;
    spikePeriodMS = 1.0 / ticksPerMS;
}

- (void)setSamplePeriodMS:(float)samplePerMS spikeChannels:(short)spikes spikePeriodMS:(float)periodMS;
{
    samplePeriodMS = samplePerMS;
    spikeChannels = spikes;
    spikePeriodMS = periodMS;
}

- (void)setSpikeTicksPerMS:(long)ticksPerMS;
{
    spikePeriodMS = 1.0 / ticksPerMS;
}

- (void)setSpikePeriodMS:(float)periodMS;
{
    spikePeriodMS = periodMS;
}

- (void)setFreeze:(BOOL)state {

    freeze = state;
}

- (NSSize)sizePix {

    return NSMakeSize(kBaseWidthPix, [self bounds].size.height);
}

- (void)spikeChannel:(short)channel time:(long)time;
{
    long spikeTimeMS; 
    
    spikeTimeMS = time * spikePeriodMS + spikeTimeBaseMS;
    if (channel < kSpikePlots && spikeTimeBaseMS > 0) {
        [spikePlots[channel] addSpike:[NSNumber numberWithLong:spikeTimeMS]];
        [self updateEventTime:spikeTimeMS];
    }
}

- (void) spikeZeroTimeMS:(long)zeroTimeMS {

	spikeTimeBaseMS = lastEventTimeMS = zeroTimeMS - timeOffsetMS;
}


- (void)stimulusBarColor:(NSColor *)color eventTime:(NSNumber *)timeMS {

	long stimulusBarTimeMS = [timeMS longValue] - timeOffsetMS;
	
    [stimPlot addStim:color time:[NSNumber numberWithLong:stimulusBarTimeMS]];
	[self updateEventTime:stimulusBarTimeMS];
}

- (void)updateEventTime:(long)timeMS {

//	NSRect b, scrollRect, drawRect;
//	float scrollFraction;							// the fraction of the view rect that needs to scroll
//	double deltaTimeMS;
	
//	scrollFraction = (timeMS - lastEventTimeMS) / durationMS;
	if (freeze) {
		lastEventTimeMS = timeMS;
		return;
	}
	
	lastEventTimeMS = timeMS;
	[self setNeedsDisplay:YES];
	return;

/*	

The following code was used for scrolling the view, rather than redrawing it entirely on each drawRect.

	if (scrollFraction >= 1.0) {					// if the view is wholly displaced, signal a complete display
		lastEventTimeMS = timeMS;
		[self setNeedsDisplay:YES];
		return;
	}
	if (waitingForDrawRect) {
		return;
	}
	b = drawRect = scrollRect = [self bounds];
	drawRect.size.height = round(scrollFraction * b.size.height);
	if (drawRect.size.height < 1.0) {
		return;
	}
	scrollRect.origin.y = drawRect.size.height;
	scrollRect.size.height = drawRect.origin.y = b.size.height - drawRect.size.height;
	[self scrollRect:scrollRect by:NSMakeSize(0, -drawRect.size.height)];
	deltaTimeMS = timeMS - lastEventTimeMS;
	lastEventTimeMS += deltaTimeMS * drawRect.size.height / (scrollFraction * b.size.height);
	waitingForDrawRect = YES;
	[self setNeedsDisplayInRect:drawRect];
*/
}

@end
