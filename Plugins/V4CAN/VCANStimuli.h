/*
VCANStimuli.h
*/

#import "VCAN.h"
#import "VCANDigitalOut.h"

@interface VCANStimuli : NSObject {

	BOOL					abortStimuli;
	BOOL					activeTargets[kStimLocs];
	LLFixTarget				*cueSpot;
	DisplayParam			display;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	LLGabor					*gabors[kStimLocs];
    long                    interstimFrames[kStimPerState];     // interstim durations to be used with specific stim
	LLIntervalMonitor 		*monitor;
	short					selectTable[kStimPerState];
	NSMutableArray			*stimList;
    long                    stimSequence[kStimPerState];
	BOOL					stimulusOn;
	LLGabor					*targetGabors[kStimLocs];
	BOOL					targetPresented;
	LLFixTarget				*targetSpot;
    TrialDesc               trial;
    LLFixTarget             *errorCueSpots[kStimLocs];
}

- (void)assignMonitorInterval;
- (void)doCueSettings;
- (void)doFixSettings;
- (void)doGaborSettings;
- (void)doTargetSpotSettings;
- (void)presentStimList;
- (void)dumpStimList;
- (void)dumpStimSequence;
- (void)erase;
- (short *)expandStimType:(long)stimType;
- (LLGabor *)gabor;
- (long)indexForStimTypes:(StimDesc)stimDesc;
- (void)initGabors;
- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial listTypes:(short *)listTypes 
                        stimTypes:(short *)types;
- (BOOL)isTargetActiveAtIndex:(long)index;
- (long)jitteredInterstimFrames;
- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
- (void)makeStimList:(TrialDesc *)pTrial;
- (LLIntervalMonitor *)monitor;
- (short *)randomStimIndices;
- (short *)randomVisibleIndices;
- (void)shuffleStimSequence;
- (void)setCueSpot:(BOOL)state location:(long)loc;
- (void)setFixSpot:(BOOL)state;
- (void)startStimList;
- (BOOL)stimulusOn;
- (void)stopAllStimuli;
- (void)tallyStimuli;
- (LLGabor *)targetGabor;
- (BOOL)targetPresented;
//- (void)setErrorCueSpot:(BOOL)state location:(long)loc;
- (void)setCueAfterError;

@end
