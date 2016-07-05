//
//  SCSpikeController.m
//  SpotChange
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "SC.h"
#import "UtilityFunctions.h"
#import "SCSpikeController.h"

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
#define	displayedHists		(MIN(blockStatus.changes, kMaxOriChanges))
#define contentHeightPix	(kPlotHeightPix + kHistHeightPix * histRows + (histRows + 2) * kMarginPix)
#define histRows			(ceil(displayedHists / (double)kHistsPerRow))

@implementation SCSpikeController


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

    for (h = 0; h < kMaxOriChanges; h++) {
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
	long index;
	BlockStatus *pCurrent, *pLast;
	BOOL dirty = NO;
	
	pCurrent = &blockStatus;
	pLast = &lastBlockStatus;
	
	if (pCurrent->changes == 0) {								// not initialized yet
		return;
	}
	if (pCurrent->changes != pLast->changes) {
		dirty = YES;
		pLast->changes = pCurrent->changes;
	}
	for (index = 0; index < pCurrent->changes; index++) {
		if (pCurrent->orientationChangeDeg[index] != pLast->orientationChangeDeg[index]) {
			dirty = YES;
			pLast->orientationChangeDeg[index] = pCurrent->orientationChangeDeg[index];
		}
		if (pCurrent->validReps[index] != pLast->validReps[index]) {
			dirty = YES;
			pLast->validReps[index] = pCurrent->validReps[index];
		}
	}
	if (!dirty) {
		return;
	}
	[self makeLabels];
	[ratePlot setPoints:pCurrent->changes];
	[ratePlot setXAxisLabel:@"Alpha Change"];
	[self positionPlots];


// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

	[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0L]]; 
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
	[trialSpikes release];
	[super dealloc];
}

- (id) init;
{
    if ((self = [super initWithWindowNibName:@"SCSpikeController" defaults:[task defaults]]) != nil) {
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
	[h setData:data0 length:kMaxSpikeMS color:[NSColor colorWithDeviceRed:0.0 green:0.7 blue:0.0 alpha:0.6]];
	[h setData:data1 length:kMaxSpikeMS color:[NSColor colorWithDeviceRed:0.6 green:0.4 blue:0.2 alpha:0.6]];
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
	NSString *string;
    
	levels = blockStatus.changes;
    [labelArray removeAllObjects];
    [xAxisLabelArray removeAllObjects];
    for (index = 0; index < levels; index++) {
		string = [NSString stringWithFormat:@"%.2f", blockStatus.orientationChangeDeg[index]];
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

	for (level = 0; level < kMaxOriChanges; level++) {
		hist = [histViews objectAtIndex:level];
		if (level < displayedHists) {
			row = level / kHistsPerRow;
			column = (level % kHistsPerRow);
			[hist setFrameOrigin:NSMakePoint(kMarginPix + column * (kHistWidthPix + kMarginPix), 
					kMarginPix + (histRows - row - 1) * (kHistHeightPix + kMarginPix))];
			[hist setTitle:[NSString stringWithFormat: @"%@ %@", 
							@"Alpha Change", [labelArray objectAtIndex:level]]];
			if (row == histRows - 1) {
				[hist setXAxisLabel:@"time (ms)"];
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
//	NSColor *redColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
//	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	NSColor *grayColor = [NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:1.0];
	NSColor *greenColor = [NSColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:1.0];
	NSColor *brownColor = [NSColor colorWithCalibratedRed:0.6 green:0.4 blue:0.2 alpha:1.0];
	NSColor *plotColors[] = {greenColor, brownColor, grayColor};
//	NSColor *plotColors[] = {greenColor, brownColor};
	
	[super windowDidLoad];
	histViews = [[NSMutableArray alloc] init];
	labelArray = [[NSMutableArray alloc] init];
	xAxisLabelArray = [[NSMutableArray alloc] init];
	trialSpikes = [[NSMutableData alloc] init];
	documentView = [scrollView documentView];
    [self makeLabels];

    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the spike rate plot

	ratePlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    [ratePlot setXAxisLabel:@"Alpha Change"];
    [ratePlot setXAxisTickLabels:xAxisLabelArray];
    [ratePlot setHighlightXRangeColor:highlightColor];
	[documentView addSubview:ratePlot];
	for (loc = 0; loc < kLocations; loc++) {
		rates[loc] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxOriChanges; index++) {
			[rates[loc] addObject:[[[LLNormDist alloc] init] autorelease]];
		}
		[ratePlot addPlot:rates[loc] plotColor:plotColors[loc]];
	}
	
// Initialize the histogram views
    
    histScaling = [[[LLViewScale alloc] init] autorelease];
	for (h = 0; h < kMaxOriChanges; h++) {
		[histViews addObject:[self initHist:histScaling data0:spikeHists[0][h] data1:spikeHists[1][h]]];
	}
    [self checkParams];
	[self changeHistTimeMS];
}

- (void)blockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&blockStatus];
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
		for (index = 0; index < kMaxOriChanges; index++) {
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
	StimDesc stimDesc;
	
	[eventData getBytes:&stimDesc];
	if (stimDesc.index == (trial.targetIndex - 1)) {
		referenceOnTimeMS = [eventTime unsignedLongValue];
    }
	if (stimDesc.stim0Type == kTargetStim) {
		targetOnTimeMS = [eventTime unsignedLongValue];
	}
}


- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	LLHistView *hist;

	[eventData getBytes:&trial];
	trialStartTime = [eventTime unsignedLongValue];

	[trialSpikes setLength:0];

// Highlight the appropriate histogram

	if (histHighlightIndex != trial.orientationChangeIndex) {
		hist = [histViews objectAtIndex:histHighlightIndex];
        if (histHighlightIndex >= 0) {
            [hist setHighlightHist:NO];
        }
		histHighlightIndex = trial.orientationChangeIndex;
		hist = [histViews objectAtIndex:histHighlightIndex];
        if (histHighlightIndex >= 0) {
			[hist setHighlightHist:YES];
			[ratePlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
		}
    }

}


- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode, stimTime, startTime, loc, dirChangeIndex, updateIndex;
	long spike, spikes, spikeCount, bin, histDurMS, level, minN;
	long referenceStartTime, referenceBin, referenceSpikeCount;
	short *pSpike;
	LLHistView *hist;
	
// Update only for correct trials
// Think about if there is any reason to update for other trials.
// Maybe separate superimposed histograms for failed trials

	[eventData getBytes:&eotCode];
	if (((eotCode != kEOTCorrect) && (eotCode != kEOTFailed)) || (trial.catchTrial == YES)) {
		return;
	}

	
	histDurMS = MIN(interstimDurMS + stimDurMS + interstimDurMS, kMaxSpikeMS);
	spikes = [trialSpikes length] / sizeof(short);


//	update spikes for target
	updateIndex = (eotCode / 2);	// either correct or failed trials

	dirChangeIndex = trial.orientationChangeIndex;
	stimTime = targetOnTimeMS - trialStartTime;
	startTime = stimTime - interstimDurMS;

	referenceStartTime = referenceOnTimeMS - trialStartTime;
	
    pSpike = (short *)[trialSpikes bytes];
	for (spike = spikeCount = referenceSpikeCount = 0; spike < spikes; spike++, pSpike++) {
		bin = *pSpike * spikePeriodMS - startTime;
		referenceBin = *pSpike * spikePeriodMS - referenceStartTime;
		
		if (bin >= 0 && bin < histDurMS) {
			spikeHists[updateIndex][dirChangeIndex][bin]++;
		}
		
		bin -= interstimDurMS;					// get rid of preresponse offset
		if (bin >= kSpikeCountDelayMS && bin < kSpikeCountDelayMS + kSpikeCountPeriodMS) {
				spikeCount++;
		}
		
		if (referenceBin >= kSpikeCountDelayMS && referenceBin < kSpikeCountDelayMS + kSpikeCountPeriodMS) {
				referenceSpikeCount++;
		}
	}
	hist = [histViews objectAtIndex:dirChangeIndex];
	[hist setYUnit:(1000.0 / ++spikeHistsN[updateIndex][dirChangeIndex]) index:updateIndex];
	[hist setNeedsDisplay:YES];
	[[rates[updateIndex] objectAtIndex:dirChangeIndex] 
							addValue:(spikeCount * 1000.0 / kSpikeCountPeriodMS)];

	for (level = 0; level < blockStatus.changes; level++) {
		[[rates[2] objectAtIndex:level] 
							addValue:(referenceSpikeCount * 1000.0 / kSpikeCountPeriodMS)];
	}


	for (loc = 0, minN = LONG_MAX; loc < kLocations; loc++) {
		for (level = 0; level < blockStatus.changes; level++) {
			minN = MIN(minN, [[rates[loc] objectAtIndex:level] n]);
		}
	}
	[ratePlot setTitle:[NSString stringWithFormat:@"Average Firing Rate (n >= %ld)", minN]];
	[ratePlot setNeedsDisplay:YES];
}


@end
