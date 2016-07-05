//
//  LLXTView.h
//  Lablib
//
//  Created by John Maunsell on Wed May 21 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewScale.h"
#import "LLXTEventPlot.h"
#import "LLXTEyePlot.h"
#import "LLXTSpikePlot.h"
#import "LLXTStimPlot.h"

#define kEyePlots			2
#define kSpikePlots			2

@interface LLXTView : NSView {

    double			durationMS;
    LLXTEventPlot	*eventPlot;
	LLXTEyePlot		*eyePlots[kEyePlots];
    float			eyeWindowOrigin;
    float			eyeWindowWidth;
    float			eyeWindowWidthFactor;
    BOOL			freeze;
    LLXTEyePlot		*hEyePlot;
    long			lastEventTimeMS;
    long			lastTimePlottedMS;
    long			lastScrollTimeMS;
    NSColor			*majorGridColor;
    NSColor			*minorGridColor;
    long			sampleBaseTimeMS;
    long			sampleCount[kEyePlots];
    float			samplePeriodMS;
    LLViewScale		*scale;
    long			spikeChannels;
	LLXTSpikePlot	*spikePlots[kSpikePlots];
    float			spikePeriodMS;
    long			spikeTimeBaseMS;
    LLXTStimPlot	*stimPlot;
    long			timeOffsetMS;
    NSTimer			*timer;
    LLXTEyePlot		*vEyePlot;
    NSMutableArray	*xtPlots;					// A list of all the XT plots in the view
}

- (void)eventName:(NSString *)name eventTime:(NSNumber *)time;
- (void)eyeRect:(NSRect)rect time:(long)time;
- (void)reset:(long)resetTime;
- (void)sampleChannel:(short)channel value:(short)value;
- (void)sampleZeroTimeMS:(long)zeroTime;
- (void)setDurationS:(double)dur;
- (void)setFrameSize;
- (void)setFreeze:(BOOL)state;
- (void)setSamplePeriodMS:(float)samplePerMS;
- (void)setSamplePeriodMS:(float)samplePerMS spikeChannels:(short)spikes spikeTickPerMS:(long)ticksPerMS;
- (void)setSamplePeriodMS:(float)samplePerMS spikeChannels:(short)spikes spikePeriodMS:(float)periodMS;
- (void)setSpikeTicksPerMS:(long)ticksPerMS;
- (void)setSpikePeriodMS:(float)periodMS;
- (void)spikeChannel:(short)channel time:(long)time;
- (void) spikeZeroTimeMS:(long)zeroTimeMS;
- (void)stimulusBarColor:(NSColor *)color eventTime:(NSNumber *)time;
- (NSSize)sizePix;
- (void)updateEventTime:(long)timeMS;

@end
