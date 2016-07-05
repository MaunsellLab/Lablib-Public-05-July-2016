/*
TUNStimuli.h
*/

#import "TUN.h"

@interface TUNStimuli : NSObject {

	LLGabor 				*gabor;
	BOOL					abortStimuli;
	short					attendLoc;
	LLFixTarget				*cueSpot;
	DisplayParam			display;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	LLIntervalMonitor 		*monitor;
	LLRandomDots 			*randomDots;
	short					selectTable[kMaxSteps];
	NSMutableArray			*stimList;
	BOOL					stimulusOn;
}

- (void)doCueSettings;
- (void)doFixSettings;
- (void)doStimSettings:(long)stimTypeIndex;
- (void)dumpStimList;
- (void)erase;
- (LLGabor *)gabor;
- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial stimIndex:(long)stimIndex;
- (void)makeStimList:(TrialDesc *)pTrial;
- (LLIntervalMonitor *)monitor;
- (void)prepareOneStimulus:(StimDesc *)pSD;
- (void)presentStimList;
- (LLRandomDots *)randomDots;
- (void)setFixSpot:(BOOL)state;
- (void)shuffleStimListFrom:(short)start count:(short)count;
- (void)startStimList;
- (BOOL)stimulusOn;
- (void)stopAllStimuli;
- (void)tallyStimuli;

@end
