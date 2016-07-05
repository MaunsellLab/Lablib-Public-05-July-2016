//
//  MTCBehaviorController.m
//  MTContrast
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "MTC.h"
#import "UtilityFunctions.h"
#import "MTCBehaviorController.h"

#define kHistsPerRow		4
#define kHistHeightPix		150
#define kHistWidthPix		((kViewWidthPix - (kHistsPerRow + 1) * kMarginPix) / kHistsPerRow)
#define kMarginPix			10
#define kPlotBinsDefault	10
#define kPlotHeightPix		250
#define kPlots				3
#define kPlotWidthPix		250
#define kViewWidthPix		(kPlots * (kPlotWidthPix) + (kPlots + 1) * kMarginPix)
#define	kXTickSpacing		100

#define contentWidthPix		(kHistsPerRow  * kHistWidthPix +  + (kHistsPerRow + 1) * kMarginPix)
#define contentHeightPix	(kPlotHeightPix + kHistHeightPix * histRows + (histRows + 2) * kMarginPix)
#define histRows			(ceil(displayedHists / (double)kHistsPerRow))
#define	displayedHists		(MIN(stimParams.levels, kMaxContrasts))

@implementation MTCBehaviorController

- (void)changeResponseTimeMS;
{
    long h, index, base, labelSpacing;
    long factors[] = {1, 2, 5};
 
// Find the appropriate spacing for x axis labels

	index = 0;
	base = 1;
    while ((responseTimeMS / kXTickSpacing) / (base * factors[index]) > 2) {
        index = (index + 1) % (sizeof(factors) / sizeof(long));
        if (index == 0) {
            base *= 10;
        }
    }
    labelSpacing = base * factors[index];

// Change the ticks and tick label spacing for each histogram

    for (h = 0; h < kMaxContrasts; h++) {
        [hist[h] setDataLength:MIN(responseTimeMS, kMaxRT)];
        [hist[h] setDisplayXMin:0 xMax:MIN(responseTimeMS, kMaxRT)];
        [hist[h] setXAxisTickSpacing:kXTickSpacing];
        [hist[h] setXAxisTickLabelSpacing:labelSpacing];
        [hist[h] setNeedsDisplay:YES];
    }
}

- (void)checkParams;
{
	StimParams *pCurrent, *pLast;
	
	pCurrent = &stimParams;
	pLast = &lastStimParams;
	
	if (pCurrent->levels == 0) {								// not initialized yet
		return;
	}
	if (pCurrent->levels != pLast->levels || pCurrent->maxValue != pLast->maxValue ||
				pCurrent->factor != pLast->factor) {
		[self makeLabels];
		[reactPlot setPoints:pCurrent->levels];
		[reactPlot setXAxisLabel:[NSString stringWithString:@"Contrasts"]];
		[perfPlot setPoints:pCurrent->levels];
		[perfPlot setXAxisLabel:[NSString stringWithString:@"Contrasts"]];
		[self positionPlots];
		pLast->levels = pCurrent->levels;
		pLast->maxValue = pCurrent->maxValue;
		pLast->factor = pCurrent->factor;

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

		[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0]]; 
	}
}

- (void)dealloc {

    [labelArray release];
	[xAxisLabelArray release];
	[super dealloc];
}

- (id) init {

    if ((self = [super initWithWindowNibName:@"MTCBehaviorController" defaults:[task defaults]]) != nil) {
    }
    return self;
}

- (LLHistView *)initHist:(LLViewScale *)scale data:(double *)data {

	LLHistView *h;
    
	h = [[[LLHistView alloc] initWithFrame:NSMakeRect(0, 0, kHistWidthPix, kHistHeightPix)
									scaling:scale] autorelease];
	[h setScale:scale];
	[h setData:data length:kMaxRT color:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.6]];
	[h setPlotBins:kPlotBinsDefault];
	[h setAutoBinWidth:YES];
	[h setSumWhenBinning:YES];
	[h hide:YES];
	[documentView addSubview:h];
	return h;
}

- (void) makeLabels;
{
    long index, levels;
	double stimValue;
	NSString *string;
    
	levels = stimParams.levels;
    [labelArray removeAllObjects];
    [xAxisLabelArray removeAllObjects];
    for (index = 0; index < levels; index++) {
		stimValue = valueFromIndex(index, &stimParams);
		string = [NSString stringWithFormat:@"%.*f",  
					[LLTextUtil precisionForValue:stimValue significantDigits:2], 
					stimValue];
		[labelArray addObject:string];
		if ((levels >= 6) && ((index % 2) == (levels % 2))) {
			[xAxisLabelArray addObject:@""];
		}
		else {
			[xAxisLabelArray addObject:string];
		}
    }
}

- (void)positionPlots;
{
	long level, row, column;

// Position the plots

	[reactPlot setFrameOrigin:NSMakePoint(kMarginPix, 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];
	[perfPlot setFrameOrigin:NSMakePoint(kMarginPix + (kPlotWidthPix + kMarginPix), 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];

// Position and hide/show the individual histograms

	for (level = 0; level < kMaxContrasts; level++) {
		if (level < displayedHists) {
			row = level / kHistsPerRow;
			column = (level % kHistsPerRow);
			[hist[level] setFrameOrigin:NSMakePoint(kMarginPix + column * (kHistWidthPix + kMarginPix), 
					kMarginPix + (histRows - row - 1) * (kHistHeightPix + kMarginPix))];
			[hist[level] setTitle:[NSString stringWithFormat: @"%@ %@", 
							@"Contrast", [labelArray objectAtIndex:level]]];
			if (row == histRows - 1) {
				[hist[level] setXAxisLabel:[NSString stringWithString:@"time (ms)"]];
			}
			[hist[level] hide:NO];
			[hist[level] setNeedsDisplay:YES];
		}
		else {
			[hist[level] hide:YES];
		}
	}
		
// Set the window to the correct size for the new number of rows and columns, forcing a 
// re-draw of all the exposed histograms.

	[documentView setFrame:NSMakeRect(0, 0, contentWidthPix, contentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(contentWidthPix, contentHeightPix)];
}

- (void) windowDidLoad {

    long index, p, h;
    NSColor *plotColor;
    NSRect maxScrollRect;
    
    [super windowDidLoad];
	documentView = [scrollView documentView];
    labelArray = [[NSMutableArray alloc] init];
    xAxisLabelArray = [[NSMutableArray alloc] init];
    [self makeLabels];
    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the reaction time plot

    reactTimes = [[[NSMutableArray alloc] init] autorelease];
    for (index = 0; index < kMaxContrasts; index++) {
        [reactTimes addObject:[[[LLNormDist alloc] init] autorelease]];
    }
	reactPlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    [reactPlot addPlot:reactTimes plotColor:nil];
    [reactPlot setXAxisLabel:[NSString stringWithString:@"Contrast"]];
    [reactPlot setXAxisTickLabels:xAxisLabelArray];
    [reactPlot setHighlightXRangeColor:highlightColor];
	[documentView addSubview:reactPlot];
	
// Initialize the performance plot.  We set the color for kEOTWrong to clear, because we don't 
// want to see those values.  They are mirror image to the correct data

	perfPlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    for (p = 0; p < kEOTs; p++) {
		performance[p] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxContrasts; index++) {
			[performance[p] addObject:[[[LLBinomDist alloc] init] autorelease]];
		}		
		if (p != kEOTWrong) {
			[perfPlot addPlot:performance[p] plotColor:[LLStandardDataEvents eotColor:p]];
		}
		else {
			[perfPlot addPlot:performance[p] plotColor:[NSColor clearColor]];
		}
    }
    [perfPlot setXAxisLabel:[NSString stringWithString:@"Contrast"]];
    [perfPlot setXAxisTickLabels:xAxisLabelArray];
    [[perfPlot scale] setAutoAdjustYMax:NO];
    [[perfPlot scale] setHeight:1];
    [perfPlot setHighlightXRangeColor:highlightColor];
	[perfPlot setHighlightYRangeFrom:0.49 to:0.51];
    [perfPlot setHighlightYRangeColor:highlightColor];
	[documentView addSubview:perfPlot];

// Initialize the histogram views
    
    plotColor = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.6];
    histScaling = [[[LLViewScale alloc] init] autorelease];
    for (h = 0; h < kMaxContrasts; h++) {
		hist[h] = [self initHist:histScaling data:rtDist[h]];
    }
    histHighlightIndex = -1;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];

// Work down from the default window max size to a default content max size, which 
// we will use as a reference for setting window max size when the view scaling is changed.

    maxScrollRect = [NSWindow contentRectForFrameRect:
        NSMakeRect(0, 0, [[self window] maxSize].width, [[self window] maxSize].height)
        styleMask:[[self window] styleMask]];

    [self checkParams];
	[self changeResponseTimeMS];
}

- (void)contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimParams];
	[self checkParams];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index, p, bin;
        
	[reactTimes makeObjectsPerformSelector:@selector(clear)];
	for (p = 0; p < kEOTs; p++) {
		[performance[p] makeObjectsPerformSelector:@selector(clear)];
	}
    for (index = 0; index < kMaxContrasts; index++) {
        for (bin = 0; bin < kMaxRT; bin++) {
            rtDist[index][bin] = 0;
        }
    }
	[[reactPlot scale] setHeight:100];					// Reset scaling as well
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)responseTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long newResponseTimeMS;
    
    [eventData getBytes:&newResponseTimeMS];
    if (responseTimeMS != newResponseTimeMS) {
        responseTimeMS = newResponseTimeMS;
        [self changeResponseTimeMS];
    }
}

- (void)saccade:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
		saccadeTimeMS = [eventTime unsignedLongValue];
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc stimDesc;
	
	[eventData getBytes:&stimDesc];
	if ((stimDesc.attendLoc == 0 && stimDesc.type0 == kTargetStim) ||
			(stimDesc.attendLoc == 1 && stimDesc.type1 == kTargetStim)) {
		targetOnTimeMS = [eventTime unsignedLongValue];
	}
}

- (void)taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long taskMode;
    
	[eventData getBytes:&taskMode];
    if (taskMode == kTaskIdle) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
            histHighlightIndex = -1;
        }
        [reactPlot setHighlightXRangeFrom:0 to:0];
        [perfPlot setHighlightXRangeFrom:0 to:0];
    }
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trial];
	
// Highlight the appropriate histogram

	if (histHighlightIndex != trial.targetContrastIndex) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
        }
		histHighlightIndex = trial.targetContrastIndex;
        if (histHighlightIndex >= 0) {
			[hist[histHighlightIndex] setHighlightHist:YES];
			[reactPlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
			[perfPlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
		}
    }
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long level, eot, minN, reactTimeMS, eotCode, ignoredValue, contrastIndex;
    long levels = stimParams.levels;
	
// Nothing to update on catch trials

	if ((contrastIndex = trial.targetContrastIndex) < 0) {
		return;
	}
	[eventData getBytes:&eotCode];
	
// Process reaction time on correct or wrong decisions

	if (eotCode == kEOTCorrect || eotCode == kEOTWrong) {
		reactTimeMS = saccadeTimeMS - targetOnTimeMS;
		[[reactTimes objectAtIndex:contrastIndex] addValue:reactTimeMS];
		if (reactTimeMS < kMaxRT) {
			rtDist[contrastIndex][reactTimeMS]++;
			[hist[contrastIndex] setNeedsDisplay:YES];
		}
		for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < levels; level++) {
			minN = MIN(minN, [[reactTimes objectAtIndex:level] n]);
		}
		[reactPlot setTitle:[NSString stringWithFormat:@"Reaction Times (n >= %d)", minN]];
		[reactPlot setNeedsDisplay:YES];
	}
	
// We increment the counts of different eots in a customized way.  We want corrects, wrongs and
// fails to add to 100%, because these are outcomes of completed trials.  Ignores are
// computed to be percentages of all trials, and are set to be averaged across all contrast values,
// because they occur before a contrast value is defined.  We leave breaks as computed on the
// contrast of the trial, but computed as a percentage of all trials.  

	ignoredValue = 0;
	switch (eotCode) {
	case kEOTWrong:
	case kEOTCorrect:
	case kEOTFailed:
		for (eot = 0; eot < kEOTs; eot++) {
			if (eot != kEOTIgnored) {
				[[performance[eot] objectAtIndex:contrastIndex] addValue:((eot == eotCode) ? 1 : 0)];
			}
		}
		break;
	case kEOTBroke:
		[[performance[kEOTBroke] objectAtIndex:contrastIndex] addValue:1];
		break;
	case kEOTIgnored:
		[[performance[kEOTBroke] objectAtIndex:contrastIndex] addValue:0];
		ignoredValue = 1;
		break;
	default:
		break;
	}
	if (eotCode < kEOTs) {
		for (level = (levels > 1) ? 1 : 0; level < levels; level++) {
			[[performance[kEOTIgnored] objectAtIndex:level] addValue:ignoredValue];
		}
	}
    for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < levels; level++) {
        for (eot = 0; eot < kEOTs; eot++) {
            if (eot != kEOTBroke && eot != kEOTIgnored) {
                minN = MIN(minN, [[performance[eot] objectAtIndex:level] n]);
            }
        }
    }
	[perfPlot setTitle:[NSString stringWithFormat:@"Trial Outcomes (n >= %d)", minN]];
	[perfPlot setNeedsDisplay:YES];
}

@end
