//
//  SpikeController.m
//  Experiment
//
//  Window with summary information about neuronal responses.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#define NoGlobals

#import "VTSpikeController.h"
#import "VT.h"
#import "UtilityFunctions.h"

NSString *spikeWindowVisibleKey = @"Spike Window Visible";
NSString *spikeWindowZoomKey = @"Spike Window Zoom";
NSString *VTSpikeAutosaveKey = @"VTSpikeAutosave";

@implementation SpikeController

- (void) changeContrasts {

    long h;
    
    [self makeContrastLabels];
    [responsePlot setPoints:contrasts];
    for (h = 0; h < contrasts; h++) {
		[hist[h] setTitle:[NSString stringWithFormat:@"Contrast %@", [labelArray objectAtIndex:h]]];
        [hist[h] hide:NO];
    }
    for ( ; h < kMaxHists; h++) {
        [hist[h] hide:YES];
    }
}

- (IBAction) changeZoom:(id)sender {

    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [[task defaults] setObject:[NSNumber numberWithInt:zoomValue] 
                forKey:spikeWindowZoomKey];
}

- (id) init {

    if ((self = [super initWithWindowNibName:@"SpikeController"]) != nil) {
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:VTSpikeAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void) makeContrastLabels {

    long index;
	double contrast;
    
    [labelArray removeAllObjects];
    for (index = 0; index < contrasts; index++) {
		contrast = valueFromIndex(index, &stimParams[stimType]);
		if (contrast >= 0.01) {
			[labelArray addObject:[NSString stringWithFormat:@"%.2f",  contrast]];
		}
		else {
			[labelArray addObject:[NSString stringWithFormat:@"%.3f",  contrast]];
		}
    }
}

- (void) positionZoomButton {

    NSRect scrollerRect, buttonRect;

    scrollerRect = [[scrollView horizontalScroller] frame];
    scrollerRect.size.width = [scrollView frame].size.width - scrollerRect.size.height - 8;
    NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, 60.0, NSMaxXEdge);
    [[scrollView horizontalScroller] setFrame:scrollerRect];
    
    buttonRect.origin.y = 1;
    [zoomButton setFrame:buttonRect];
}

- (void) setScaleFactor:(double)factor {

    NSSize maxContentSize;
    NSRect scrollFrameRect, windowFrameRect;
    double delta;
    static double scaleFactor = 1.0;
  
    if (scaleFactor != factor) {
        delta = factor / scaleFactor;
        [[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(delta, delta)];
        scaleFactor = factor;
        [self positionZoomButton];
        [scrollView display];

// Limit the maximum size of the window.  
  
        maxContentSize.width = baseMaxContentSize.width * factor;
        maxContentSize.height = baseMaxContentSize.height * factor;
        scrollFrameRect.origin = NSMakePoint(0, 0);
        scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize 
            hasHorizontalScroller:YES hasVerticalScroller:YES 
            borderType:[scrollView borderType]];
        windowFrameRect = [NSWindow frameRectForContentRect:scrollFrameRect
                styleMask:[[self window] styleMask]];
        [[self window] setMaxSize:windowFrameRect.size];
   }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {

	[[task defaults] setObject:[NSNumber numberWithBool:YES] 
                forKey:spikeWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void) windowDidLoad {

    long index, h, defaultZoom;
    NSColor *plotColor;
    NSRect maxScrollRect;

    labelArray = [[NSMutableArray alloc] init];
    [self makeContrastLabels];
    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the reaction time plot

    responses = [[[NSMutableArray alloc] init] autorelease];
    for (index = 0; index < kMaxHists; index++) {
        [responses addObject:[[[LLNormDist alloc] init] autorelease]];
    }
    [responsePlot addPlot:responses plotColor:nil];
    [responsePlot setXAxisLabel:@"contrast"];
    [responsePlot setXAxisTickLabels:labelArray];
    [responsePlot setHighlightXRangeColor:highlightColor];
    [labelArray release];				// retained by plotViews and histViews

// Initialize the histogram views
    
    hist[0] = histView0;
    hist[1] = histView1;
    hist[2] = histView2;
    hist[3] = histView3;
    hist[4] = histView4;
    hist[5] = histView5;
    hist[6] = histView6;
    hist[7] = histView7;
    plotColor = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.6];
    histScaling = [[LLViewScale alloc] init];
    for (h = 0; h < kMaxHists; h++) {
        [hist[h] setScale:histScaling];
        [hist[h] setData:spikeHists[h] length:kMaxBins color:plotColor];
        if (h > 3) {
            [hist[h] setXAxisLabel:[NSString stringWithString:@"time (ms)"]];
        }
        if ((h % 4) == 0) {
            [hist[h] setYAxisLabel:[NSString stringWithString:@"response (spikes/s)"]];
        }
        [hist[h] setPlotBins:kPlotBinsDefault];
        [hist[h] setAutoBinWidth:NO];
        [hist[h] setSumWhenBinning:NO];
    }
    [histScaling release];		// retained by each LLHistView
    histHighlightIndex = -1;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    
// Work down from the default window max size to a default content max size, which 
// we will use as a reference for setting window max size when the view scaling is changed.

    maxScrollRect = [NSWindow contentRectForFrameRect:
        NSMakeRect(0, 0, [[self window] maxSize].width, [[self window] maxSize].height)
        styleMask:[[self window] styleMask]];
    baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size 
            hasHorizontalScroller:YES hasVerticalScroller:YES
            borderType:[scrollView borderType]];
    
// Set to the default zoom.  This has to be done after setting baseMaxContentSize, 
// because setScaleFactor uses that

    defaultZoom = [[task defaults] integerForKey:spikeWindowZoomKey];
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            [self setScaleFactor:defaultZoom / 100.0];
            break;
        }
    }

    [self changeContrasts];
	[[self window] setFrameUsingName:VTSpikeAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:spikeWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
    
    [self positionZoomButton];							// position zoom must be after visible
    [super windowDidLoad];
}

- (void) windowDidResize:(NSNotification *)aNotification {

	[self positionZoomButton];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification {

    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] 
                forKey:spikeWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:


- (void) contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&stimParams[kVisualStimulus]];
}

- (void) currentStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&stimParams[kElectricalStimulus]];
}

- (void) contrasts:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long newContrasts;
    
	[eventData getBytes:&newContrasts];
    if (contrasts != newContrasts) {
        contrasts = newContrasts;
        [self changeContrasts];
	}
}

- (void) intervalMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&intervalMS];
}

- (void) prestimMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&prestimMS];
}

- (void) preStimuli:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    prestimOnTimeMS = [eventTime unsignedLongValue];
    validSpikes = YES;
}

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long h, bin;
        
    [responses makeObjectsPerformSelector:@selector(clear)];
    for (h = 0; h < kMaxHists; h++) {
        [hist[h] setPlotBins:kPlotBinsDefault];
        [hist[h] setDataLength:bins];
        [hist[h] setXAxisTickSpacing:intervalMS];
        [hist[h] setDisplayXMin:-prestimMS xMax:bins - prestimMS];
        [hist[h] clearAllFills];
        [hist[h] fillXFrom:0 to:intervalMS color:highlightColor];
        [hist[h] fillXAxisFrom:0 to:intervalMS heightPix:4 color:highlightColor];
        [hist[h] setNeedsDisplay:YES];
        
        spikeHistsN[h] = 0.0;
        for (bin = 0; bin < kMaxBins; bin++) {
            spikeHists[h][bin] = 0.0;
        }
    }
	[[responsePlot scale] setHeight:10];					// Reset scaling as well
}

- (void) responseTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long h, responseTimeMS;
    static long lastResponseTimeMS = -1;
    
	[eventData getBytes:&responseTimeMS];
    if (responseTimeMS != lastResponseTimeMS) {
        for (h = 0; h < kMaxLevels; h++) {
            [hist[h] setDataLength:bins];
            [hist[h] setNeedsDisplay:YES];
        }
	}
    lastResponseTimeMS = responseTimeMS;
}

- (void) spike:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long bin;
    TimestampData timestamp;
    
    if (!validSpikes) {
        return;
    }
	[eventData getBytes:&timestamp];
    if (timestamp.channel == 0) {							// only channel 0 is counted
        bin = timestamp.time - (prestimOnTimeMS - trialStartTimeMS);
        if (bin >= 0 && bin < kMaxBins) {					// only spikes during stimulus presentation
            trialHist[bin]++;								// add to spike histogram
            if (bin >= prestimMS && bin < prestimMS + intervalMS) {
                spikeCount++;								// add to spike count
            }
        }
    }
}

- (void) stimulusOn:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    stimOnTimeMS = [eventTime unsignedLongValue];
}

- (void) stimulusType:(NSData *)eventData eventTime:(NSNumber *)eventTime {
    
	[eventData getBytes:&stimType];
}

- (void) taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long taskMode;
    
	[eventData getBytes:&taskMode];
    if (taskMode == kTaskIdle) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
            histHighlightIndex = -1;
        }
        [responsePlot setHighlightXRangeFrom:0 to:0];
    }
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long bin, contrast, minN;
	long eotCode;
    
	[eventData getBytes:&eotCode];
	if (eotCode == kEOTCorrect) {

// Update the spike histogram for this stimulus

        for (bin = 0; bin < bins; bin++) {
            spikeHists[contrastIndex][bin] += trialHist[bin]; 
        }
        spikeHistsN[contrastIndex]++;
        [hist[contrastIndex] setYUnit:1000.0 / spikeHistsN[contrastIndex]];
        [hist[contrastIndex] setNeedsDisplay:YES];
        
// Update the plot of response averages

        [[responses objectAtIndex:contrastIndex] addValue:spikeCount * 1000.0 / intervalMS];
        for (contrast = 0, minN = LONG_MAX; contrast < contrasts; contrast++) {
            minN = MIN(minN, [[responses objectAtIndex:contrast] n]);
        }
        [responsePlot setTitle:[NSString stringWithFormat:@"Average Rate of Firing (n >= %d)", minN]];
        [responsePlot setNeedsDisplay:YES];
    }
    validSpikes = NO;
}

- (void) trialStart:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long bin;
    
	trialStartTimeMS = [eventTime unsignedLongValue];
	[eventData getBytes:&contrastIndex];
	if (histHighlightIndex != contrastIndex) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
        }
        histHighlightIndex = contrastIndex;
        [hist[histHighlightIndex] setHighlightHist:YES];
        [responsePlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
    }
    spikeCount = 0;
    for (bin = 0; bin < kMaxBins; bin++) {
        trialHist[bin] = 0;
    }
}

@end
