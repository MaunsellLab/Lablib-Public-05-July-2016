//
//  VISpikeController.m
//  VICAN
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2012 All rights reserved.
//

#define NoGlobals

typedef enum {kSpontCondition = 0, kNullCondition, kNullNullCondition, kPrefNullCondition, kPrefPrefCondition, 
                kPrefCondition, kConditions} TaskCondition;

#import "VI.h"
#import "VISpikeController.h"

#define kContentHeightPix	((kPlotHeightPix + kMarginPix) + kRFStimTypes * (kHistHeightPix + kMarginPix) + \
                                    (kLabelHeightPix + kMarginPix) + kMarginPix)
#define kContentWidthPix	((kRFStimTypes * kNumHistPerSet) * (kHistWidthPix + kMarginPix) + kMarginPix)

#define kHistHeightPix		200
#define kHistWidthPix		200

#define kHistMenuX          (kMarginPix + 2 * (kMarginPix + kPlotWidthPix))
#define kHistMenuY          kLabelOriginY

#define kLabelOriginY       (kRFStimTypes * (kHistHeightPix + kMarginPix) + kMarginPix)
#define kLabelHeightPix     17

#define kPlotBinsDefault	10
#define kPlotOriginY        (kLabelOriginY + kLabelHeightPix + kMarginPix)
#define kPlotHeightPix		250
#define kPlotRows			1
#define kPlotWidthPix		(2 * kHistWidthPix)

#define kMarginPix			4
#define kMaxTicks			6
#define kSetOffsetPix		(kRFStimTypes * (kMarginPix + kHistWidthPix))
#define kSpikeCountPeriodMS	200
#define kSpikeCountDelayMS	50
#define	kXTickSpacing		100


NSString *VIHistogramSetIndexKey = @"VIHistogramSetIndex";

@implementation VISpikeController


- (void)changeHistTimeMS;
{
    long set, c0, c1, index, base, labelSpacing, histDurMS;
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
	
	for (set = 0; set < kNumHistStates; set++) {
		for (c0 = 0; c0 < kRFStimTypes; c0++) {
			for (c1 = 0; c1 < kRFStimTypes; c1++) {
				hist = histViews[set][c0][c1];
				[hist setDataLength:histDurMS];
				[hist setDisplayXMin:0 xMax:histDurMS];
				[hist setXAxisTickSpacing:kXTickSpacing];
				[hist setXAxisTickLabelSpacing:labelSpacing];
				[hist clearAllFills]; 
				[hist fillXFrom:interstimDurMS to:(interstimDurMS + stimDurMS) 
						  color:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0]];
				[hist setNeedsDisplay:YES];
			}
		}
	}
}

- (void)dealloc;
{
    long index;
	
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self 
                                forKeyPath:[NSString stringWithFormat:@"values.%@", VIHistogramSetIndexKey]];
    for (index = 0; index < kAttendTypes; index++) {
		[rates[0][index] release];
		[rates[1][index] release];
	}
	[xAxisLabelArray release];
	[stimList release];
	[stimTimes release];
	[trialSpikes release];
	[super dealloc];
}

- (id) init;
{
    (self = [super initWithWindowNibName:@"VISpikeController" defaults:[task defaults]]);
    return self;
}

- (LLHistView *)myInitHistWithScaling:(LLViewScale *)scaling doXAxisLabel:(BOOL)doLabel; 
{
	LLHistView *h;
	h = [[[LLHistView alloc] initWithFrame:NSMakeRect(0, 0, kHistWidthPix, kHistHeightPix)
								   scaling:scaling] autorelease];
	[h setScale:scaling];
	[h setPlotBins:kPlotBinsDefault];
	[h setAutoBinWidth:NO];
	[h setSumWhenBinning:NO];
	[h setHidden:YES];
	[h setXAxisLabel:(doLabel ? @"time (ms)" : @"")];
	[documentView addSubview:h];
	return h;
}

- (void)loadHistograms;
{
	long state, stim0, stim1;
    BOOL doInIn = ([[task defaults] integerForKey:VIHistogramSetIndexKey] == 0);
    
    // Reposition the histograms
	
	for (state = 0; state < kNumHistStates; state++) {
		for (stim0 = 0; stim0 < kRFStimTypes; stim0++) {
			for (stim1 = 0; stim1 < kRFStimTypes; stim1++) {
				[histViews[state][stim0][stim1] setHidden:!(doInIn ^ (state / kRFStimTypes))];
			}
		}
	}
}    

- (void)mouseDown:(NSEvent *)theEvent;
{
    long set, c0, c1;
	
	for (set = 0; set < kNumHistStates; set++) {
		for (c0 = 0; c0 < kRFStimTypes; c0++) {
			for (c1 = 0; c1 < kRFStimTypes; c1++) {
				[histViews[set][c0][c1] mouseDown:theEvent];
			}
		}
	}
	[ratePlot[0] mouseDown:theEvent];
	[ratePlot[1] mouseDown:theEvent];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
                                                                            context:(void *)context;
{
	NSString *key;
    
	key = [keyPath pathExtension];
	if ([key isEqualTo:VIHistogramSetIndexKey]) {
        [self loadHistograms];
    }
}

- (void)windowDidLoad;
{
    long index, condition, state, c0, c1, taskCond;
    LLViewScale		*viewScaling;
    NSTextField     *histLabels[] = {histLabel0, histLabel1, histLabel2};
	NSColor *redColor = [NSColor colorWithDeviceRed:0.6 green:0.0 blue:0.0 alpha:0.7];		// Attend Out Preferred
	NSColor *greenColor = [NSColor colorWithDeviceRed:0.0 green:0.4 blue:0.0 alpha:0.7];	// Attend Out Null
	NSColor *blueColor = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.8 alpha:0.7];		// Attend Out Intermediate}
	NSColor *colors[kAttendTypes] = {redColor, greenColor, blueColor};
    NSString *labels[] = {@"----", @"Null", @"Pref"};
        
	[super windowDidLoad];
	xAxisLabelArray = [[NSMutableArray alloc] init];
	stimList = [[NSMutableArray alloc] init];
	stimTimes = [[NSMutableArray alloc] init];
	trialSpikes = [[NSMutableData alloc] init];
	documentView = [scrollView documentView];
    [documentView setFrame:NSMakeRect(0, 0, kContentWidthPix, kContentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(kContentWidthPix, kContentHeightPix)];
	
	// Initialize the rate plots for the normalization task
	
    viewScaling = [[[LLViewScale alloc] init] autorelease];
    for (taskCond = 0; taskCond < kTaskConditions; taskCond++) {
        ratePlot[taskCond] = [[[LLPlotView alloc] initWithFrame:NSMakeRect(
                       kMarginPix + taskCond * (kMarginPix + kPlotWidthPix), kPlotOriginY,
                       kPlotWidthPix, kPlotHeightPix) scaling:viewScaling] autorelease];
        [ratePlot[taskCond] setXAxisTickLabels:[NSArray arrayWithObjects:
                                      @"----", @"Null", @"Null/Null", @"Pref/Null", @"Pref/Pref", @"Pref", nil]];
        for (index = 0; index < kAttendTypes; index++) {
            rates[taskCond][index] = [[NSMutableArray alloc] init];
            for (condition = 0; condition < kConditions; condition++) {
                [rates[taskCond][index] addObject:[[[LLNormDist alloc] init] autorelease]];
            }
            [ratePlot[taskCond] addPlot:rates[taskCond][index] plotColor:colors[index]];
            [ratePlot[taskCond] setColor:colors[index] forPlot:index];
        }
        [ratePlot[taskCond] setPoints:kConditions];
        [documentView addSubview:ratePlot[taskCond]];
	}
	
    viewScaling = [[[LLViewScale alloc] init] autorelease];
	for (state = 0; state < kNumHistStates; state++) {
		for (c0 = 0; c0 < kRFStimTypes; c0++) {
			for (c1 = 0; c1 < kRFStimTypes; c1++) {
				histViews[state][c0][c1] = [self myInitHistWithScaling:viewScaling doXAxisLabel:(c1 == 0 && c0 == 0)];
                [histViews[state][c0][c1] setData:spikeHists[state][c0][c1] length:kMaxSpikeMS 
                        color:stateColors[state % (kNumHistStates / 2) + state / (kNumHistStates / 2) * (kNumStates / 2)]];
				[histViews[state][c0][c1] setFrameOrigin:NSMakePoint(
                        kMarginPix + (state % kRFStimTypes) * kSetOffsetPix + c0 * (kMarginPix + kHistWidthPix),
                        kMarginPix + c1 * (kMarginPix + kHistWidthPix))];
				[histViews[state][c0][c1] setTitle:[NSString stringWithFormat:@"%@/%@",  labels[c0], labels[c1]]];
			}
		}
	}

    for (c0 = 0; c0 < kRFStimTypes; c0++) {
        [histLabels[c0] setFrameOrigin:NSMakePoint((c0 * kRFStimTypes) * (kMarginPix + kHistWidthPix) + kMarginPix, kLabelOriginY)];
        [histLabels[c0] setNeedsDisplay:YES];
    }
    [histSelectMenu setFrameOrigin:NSMakePoint(kHistMenuX, kHistMenuY)];
    
	[self changeHistTimeMS];
    [self loadHistograms];

    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
        forKeyPath:[NSString stringWithFormat:@"values.%@", VIHistogramSetIndexKey]
        options:NSKeyValueObservingOptionNew context:nil];
}

- (void)interstimMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&interstimDurMS length:sizeof(long)];
	[self changeHistTimeMS];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long index, set, c0, c1, bin;
	
	for (index = 0; index < kAttendTypes; index++) {
		[rates[0][index] makeObjectsPerformSelector:@selector(clear)];
		[rates[1][index] makeObjectsPerformSelector:@selector(clear)];
	}
	for (set = 0; set < kNumHistStates; set++) {
		for (c0 = 0; c0 < kRFStimTypes; c0++) {
			for (c1 = 0; c1 < kRFStimTypes; c1++) {
				spikeHistsN[set][c0][c1] = 0;
				for (bin = 0; bin < kMaxSpikeMS; bin++) {
					spikeHists[set][c0][c1][bin] = 0;
				}
			}
		}
	}
	[[ratePlot[0] scale] setHeight:10];						// Reset scaling as well
	[[ratePlot[1] scale] setHeight:10];						// Reset scaling as well
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)spikeData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[trialSpikes appendData:eventData];
}

- (void)stimDurationMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimDurMS length:sizeof(long)];
	[self changeHistTimeMS];
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long t;
	BOOL valid;
	StimDesc *pSD;
	
	pSD = (StimDesc *)[eventData bytes];
	for (t = 0, valid = YES; t < kStimLocs; t++) {
		valid = (pSD->listTypes[t] == kValidStim) ? valid : NO;
	}
	if (valid) {
		[stimList addObject:[NSValue valueWithBytes:pSD objCType:@encode(StimDesc)]];
		[stimTimes addObject:eventTime];
	}
}

- (void)tallyResponses;
{
	long index, stimTime, startTime, setIndex, histSetIndex, condition;
	long spike, numSpikes, spikeCount, bin, histDurMS, minN;
	short *pSpike;
	StimDesc stimDesc;
	LLHistView *hist;
	NSValue *value;
	NSNumber *number;
	NSEnumerator *stimEnumerator, *timeEnumerator;
    AttendType attendIndex;
    TaskCondition conditionIndices[2][kRFStimTypes][kRFStimTypes] = 
    {               {{kSpontCondition,   kNullCondition,      kPrefCondition},
                    {kNullCondition,     kNullNullCondition,  kPrefNullCondition},
                    {kPrefCondition,     kPrefNullCondition,  kPrefPrefCondition}},
    
                    {{kSpontCondition,   -1,                  -1},
                    {kNullCondition,     kNullNullCondition,  -1},
                    {kPrefCondition,     kPrefNullCondition,  kPrefPrefCondition}}};

	stimEnumerator = [stimList objectEnumerator];
	timeEnumerator = [stimTimes objectEnumerator];
	histDurMS = MIN(interstimDurMS + stimDurMS + interstimDurMS, kMaxSpikeMS);
	numSpikes = [trialSpikes length] / sizeof(short);
    setIndex = trial.attendState / (kNumStates / 2);                     // In/In or In/Out
    histSetIndex = MIN((kNumHistPerSet - 1), (trial.attendState % (kNumStates / 2))) + setIndex * kNumHistPerSet;
	while (value = [stimEnumerator nextObject]) {					// For each stimulus
		[value getValue:&stimDesc];
        number = [timeEnumerator nextObject];
		stimTime = [number longValue] - trialStartTime;
		startTime = stimTime - interstimDurMS;
		for (spike = spikeCount = 0, pSpike = (short *)[trialSpikes bytes]; spike < numSpikes; spike++, pSpike++) {
			bin = *pSpike - startTime;
			if (bin >= 0 && bin < histDurMS) {
				spikeHists[histSetIndex][stimDesc.stimTypes[kGabor0]][stimDesc.stimTypes[kGabor1]][bin]++;
			}
			bin -= (interstimDurMS + kSpikeCountDelayMS);			// offset to start of counting period
			if (bin >= 0 && bin < kSpikeCountPeriodMS) {
				spikeCount++;
			}
		}
        hist = histViews[histSetIndex][stimDesc.stimTypes[kGabor0]][stimDesc.stimTypes[kGabor1]];
        [hist setYUnit:(1000.0 / 
                        ++spikeHistsN[histSetIndex][stimDesc.stimTypes[kGabor0]][stimDesc.stimTypes[kGabor1]])]; 
        [hist setNeedsDisplay:YES];
		
		// Update rate plots
        
        attendIndex = kAttendOut;
        if (trial.attendLoc != kGaborFar0 && trial.attendLoc != kGaborFar1) {
            if (setIndex == 0) {
                if (stimDesc.stimTypes[trial.attendLoc] == kPrefStim) {
                    attendIndex = kAttendPref;
                }
                else if (stimDesc.stimTypes[trial.attendLoc] == kNullStim) {
                    attendIndex = kAttendNull;
                }
            }
            else {
                if (stimDesc.stimTypes[kGabor0] == kPrefStim) {
                    attendIndex = kAttendPref;
                }
                else if (stimDesc.stimTypes[kGabor0] == kNullStim) {
                    attendIndex = kAttendNull;
                }
            }
        }
        condition = conditionIndices[setIndex][stimDesc.stimTypes[kGabor0]][stimDesc.stimTypes[kGabor1]];
        if (condition >= 0) {
            [[rates[setIndex][attendIndex] objectAtIndex:condition] 
                                                addValue:(spikeCount * 1000.0 / kSpikeCountPeriodMS)];
        }
    }
	for (index = 0, minN = LONG_MAX; index < kAttendTypes; index++) {
		for (condition = 0; condition < kConditions; condition++) {
            if (index == kAttendPref && condition < kPrefNullCondition) {
                continue;
            }
            if (index == kAttendNull && (condition < kNullCondition || 
                                         condition > ((setIndex == 0) ? kPrefNullCondition : kNullNullCondition))) {
                continue;
            }
			minN = MIN(minN, [[rates[setIndex][index] objectAtIndex:condition] n]);
		}
	}
	[ratePlot[setIndex] setTitle:[NSString stringWithFormat:@"In/%@ Configuration (n >= %ld)", 
                                 (setIndex == 0) ? @"In" : @"Out", minN]];
	[ratePlot[setIndex] setNeedsDisplay:YES];
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&trial length:sizeof(TrialDesc)];
	trialStartTime = [eventTime longValue];
	
	// Highlight the appropriate histogram
	
	[trialSpikes setLength:0];
	[stimList removeAllObjects];
	[stimTimes removeAllObjects];
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode;
	
	// Don't update on incorrectly completed trials
	
	[eventData getBytes:&eotCode length:sizeof(long)];
	if (eotCode != kEOTCorrect) {
		return;
	}
	
	// Only add spikes when both the preferred and null stimuli are both either 100% or 0% contrast.  The stimulus list
	// has already been screened to contain only valid stimuli.
	
	[self tallyResponses];
}

@end
