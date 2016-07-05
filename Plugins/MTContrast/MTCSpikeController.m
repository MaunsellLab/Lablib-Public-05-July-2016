//
//  MTCSpikeController.m
//  MTContrast
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "MTC.h"
#import "UtilityFunctions.h"
#import "MTCSpikeController.h"

#define kSpikeCountPeriodMS	150
#define kSpikeCountDelayMS	50
#define kHistsPerRow		4
#define kHistHeightPix		150
#define kHistWidthPix		((kContentWidthPix - (kHistsPerRow + 1) * kMarginPix) / kHistsPerRow)
#define kMarginPix			10
#define kPlotBinsDefault	10
#define kPlotHeightPix		250
#define kPlots				3
#define kPlotWidthPix		250
#define kContentWidthPix		(kPlots * kPlotWidthPix + (kPlots + 1) * kMarginPix)
#define	kXTickSpacing		100

//#define contentWidthPix		(kHistsPerRow  * kHistWidthPix + (kHistsPerRow + 1) * kMarginPix)
#define	displayedHists		(MIN(stimParams.levels, kMaxContrasts))
#define contentHeightPix	(kPlotHeightPix + kHistHeightPix * histRows + (histRows + 2) * kMarginPix)
#define histRows			(ceil(displayedHists / (double)kHistsPerRow))

@implementation MTCSpikeController


- (void)changeHistTimeMS;
{
    long h, index, base, labelSpacing, histDurMS;
	LLHistView *hist;
    long factors[] = {1, 2, 5};
 
// Find the appropriate spacing for x axis labels

	histDurMS = MIN(interstimDurMS + stimDurMS + interstimDurMS, kMaxSpikeMS);
	index = 0;
	base = 1;
    while ((histDurMS / kXTickSpacing) / (base * factors[index]) > 2) {
        index = (index + 1) % (sizeof(factors) / sizeof(long));
        if (index == 0) {
            base *= 10;
        }
    }
    labelSpacing = base * factors[index];

// Change the ticks and tick label spacing for each histogram

    for (h = 0; h < kMaxContrasts; h++) {
		hist = [histViews objectAtIndex:h];
        [hist setDataLength:MIN(histDurMS, kMaxSpikeMS)];
        [hist setDisplayXMin:0 xMax:MIN(histDurMS, kMaxSpikeMS)];
        [hist setXAxisTickSpacing:kXTickSpacing];
        [hist setXAxisTickLabelSpacing:labelSpacing];
		[hist clearAllFills]; 
		[hist fillXFrom:interstimDurMS to:(interstimDurMS + stimDurMS) 
				color:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0]];
        [hist setNeedsDisplay:YES];
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
		[ratePlot setPoints:pCurrent->levels];
		[ratePlot setXAxisLabel:[NSString stringWithString:@"Contrasts"]];
		[self positionPlots];
		pLast->levels = pCurrent->levels;
		pLast->maxValue = pCurrent->maxValue;
		pLast->factor = pCurrent->factor;

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

		[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0L]]; 
	}
}

- (void)dataParam:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	DataParam *pParam = (DataParam *)[eventData bytes];
	
	if (strcmp((char *)&pParam->dataName, "spikeData") == 0) {
		spikePeriodMS = pParam->timing;
	}
}

- (void)dealloc {

    [histViews release];
    [labelArray release];
	[xAxisLabelArray release];
	[stimList release];
	[stimTimes release];
	[trialSpikes release];
	[super dealloc];
}

- (id) init;
{
    if ((self = [super initWithWindowNibName:@"MTCSpikeController" defaults:[task defaults]]) != nil) {
		spikePeriodMS = 1.0;
    }
    return self;
}

- (LLHistView *)initHist:(LLViewScale *)scale data0:(double *)data0 data1:(double *)data1;
{
	LLHistView *h;
    
	h = [[[LLHistView alloc] initWithFrame:NSMakeRect(0, 0, kHistWidthPix, kHistHeightPix)
									scaling:scale] autorelease];
	[h setScale:scale];
	[h setData:data0 length:kMaxSpikeMS color:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.6]];
	[h setData:data1 length:kMaxSpikeMS color:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.4]];
	[h setPlotBins:kPlotBinsDefault];
	[h setAutoBinWidth:NO];
	[h setSumWhenBinning:NO];
	[h hide:YES];
	[documentView addSubview:h];
	return h;
}

- (void)makeLabels;
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

- (void)mouseDown:(NSEvent *)theEvent;
{
	[histViews makeObjectsPerformSelector:@selector(mouseDown:) withObject:theEvent];
	[ratePlot mouseDown:theEvent];
}

- (void)positionPlots;
{
	long level, row, column;
	LLHistView *hist;

// Position the plots

	[ratePlot setFrameOrigin:NSMakePoint(kMarginPix, 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];

// Position and hide/show the individual histograms

	for (level = 0; level < kMaxContrasts; level++) {
		hist = [histViews objectAtIndex:level];
		if (level < displayedHists) {
			row = level / kHistsPerRow;
			column = (level % kHistsPerRow);
			[hist setFrameOrigin:NSMakePoint(kMarginPix + column * (kHistWidthPix + kMarginPix), 
					kMarginPix + (histRows - row - 1) * (kHistHeightPix + kMarginPix))];
			[hist setTitle:[NSString stringWithFormat: @"%@ %@", 
							@"Contrast", [labelArray objectAtIndex:level]]];
			if (row == histRows - 1) {
				[hist setXAxisLabel:[NSString stringWithString:@"time (ms)"]];
			}
			[hist hide:NO];
			[hist setNeedsDisplay:YES];
		}
		else {
			[hist setFrameOrigin:NSMakePoint(-(kMarginPix + column * (kHistWidthPix + kMarginPix)), 
					kMarginPix + (histRows - row - 1) * (kHistHeightPix + kMarginPix))];
			[hist hide:YES];
		}
	}
		
// Set the window to the correct size for the new number of rows and columns, forcing a 
// re-draw of all the exposed histograms.

	[documentView setFrame:NSMakeRect(0, 0, kContentWidthPix, contentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(kContentWidthPix, contentHeightPix)];
}

- (void) windowDidLoad {

    long index, h, loc;
	NSColor *redColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	NSColor *plotColors[] = {redColor, blueColor};
	
	[super windowDidLoad];
	histViews = [[NSMutableArray alloc] init];
	labelArray = [[NSMutableArray alloc] init];
	xAxisLabelArray = [[NSMutableArray alloc] init];
	stimList = [[NSMutableArray alloc] init];
	stimTimes = [[NSMutableArray alloc] init];
	trialSpikes = [[NSMutableData alloc] init];
	documentView = [scrollView documentView];
    [self makeLabels];

// Initialize the reaction time plot

	ratePlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    [ratePlot setXAxisLabel:[NSString stringWithString:@"Contrast"]];
    [ratePlot setXAxisTickLabels:xAxisLabelArray];
	[documentView addSubview:ratePlot];
	for (loc = 0; loc < kLocations; loc++) {
		rates[loc] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxContrasts; index++) {
			[rates[loc] addObject:[[[LLNormDist alloc] init] autorelease]];
		}
		[ratePlot addPlot:rates[loc] plotColor:plotColors[loc]];
	}
	
// Initialize the histogram views
    
    histScaling = [[[LLViewScale alloc] init] autorelease];
	for (h = 0; h < kMaxContrasts; h++) {
		[histViews addObject:[self initHist:histScaling data0:spikeHists[0][h] data1:spikeHists[1][h]]];
	}
    [self checkParams];
	[self changeHistTimeMS];
}

- (void)contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimParams];
	[self checkParams];
}

- (void)interstimMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&interstimDurMS];
	[self changeHistTimeMS];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long index, loc, bin;
        
	for (loc = 0; loc < kLocations; loc++) {
		[rates[loc] makeObjectsPerformSelector:@selector(clear)];
		for (index = 0; index < kMaxContrasts; index++) {
			spikeHistsN[loc][index] = 0;
			for (bin = 0; bin < kMaxSpikeMS; bin++) {
				spikeHists[loc][index][bin] = 0;
			}
		}
	}
	[[ratePlot scale] setHeight:10];					// Reset scaling as well
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)spikeData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[trialSpikes appendData:eventData];
}

- (void)stimDurationMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimDurMS];
	[self changeHistTimeMS];
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc *pSD;
	
	pSD = (StimDesc *)[eventData bytes];
	if (pSD->type0 == kValidStim && pSD->type1 == kValidStim) {
		[stimList addObject:[NSValue valueWithBytes:pSD objCType:@encode(StimDesc)]];
		[stimTimes addObject:eventTime];
	}
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trial];
	trialStartTime = [eventTime longValue];

// Highlight the appropriate histogram

	[trialSpikes setLength:0];
	[stimList removeAllObjects];
	[stimTimes removeAllObjects];
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode, stimTime, startTime, contrastIndex, loc;
	long spike, spikes, spikeCount, bin, histDurMS, level, minN;
	short *pSpike;
	StimDesc stimDesc;
	LLHistView *hist;
	NSValue *value;
	NSNumber *number;
	NSEnumerator *stimEnumerator, *timeEnumerator;
	
// Nothing to update on catch trials

	[eventData getBytes:&eotCode];
	if (eotCode != kEOTCorrect) {
		return;
	}
	histDurMS = MIN(interstimDurMS + stimDurMS + interstimDurMS, kMaxSpikeMS);
	spikes = [trialSpikes length] / sizeof(short);
	stimEnumerator = [stimList objectEnumerator];
	timeEnumerator = [stimTimes objectEnumerator];
	while (value = [stimEnumerator nextObject]) {
		[value getValue:&stimDesc];
		contrastIndex = stimDesc.contrastIndex;
		number = [timeEnumerator nextObject];
		stimTime = [number longValue] - trialStartTime;
		startTime = stimTime - interstimDurMS;
		for (spike = spikeCount = 0, pSpike = (short *)[trialSpikes bytes]; spike < spikes; spike++, pSpike++) {
			bin = *pSpike * spikePeriodMS - startTime;
			if (bin >= 0 && bin < histDurMS) {
				spikeHists[trial.attendLoc][contrastIndex][bin]++;
			}
			bin -= interstimDurMS;					// get rid of preresponse offset
			if (bin >= kSpikeCountDelayMS && bin < kSpikeCountDelayMS + kSpikeCountPeriodMS) {
					spikeCount++;
			}
		}
		hist = [histViews objectAtIndex:contrastIndex];
        [hist setYUnit:(1000.0 / ++spikeHistsN[trial.attendLoc][contrastIndex])];
        [hist setNeedsDisplay:YES];
		[[rates[trial.attendLoc] objectAtIndex:contrastIndex] 
								addValue:(spikeCount * 1000.0 / kSpikeCountPeriodMS)];
	}
	for (loc = 0, minN = LONG_MAX; loc < kLocations; loc++) {
		for (level = 0; level < stimParams.levels; level++) {
			minN = MIN(minN, [[rates[loc] objectAtIndex:level] n]);
		}
	}
	[ratePlot setTitle:[NSString stringWithFormat:@"Average Firing Rate (n >= %d)", minN]];
	[ratePlot setNeedsDisplay:YES];
}

@end
