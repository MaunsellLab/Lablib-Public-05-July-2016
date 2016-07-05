/*
SCStimuli.h
*/

#import "SC.h"

@interface SCStimuli : NSObject {

	BOOL					abortStimuli;
	DisplayParam			display;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	LLGabor 				*gabor1;
	LLGabor 				*gabor0;
	LLIntervalMonitor 		*monitor;
    float                   orientationChangeDeg;
	short					selectTable[kMaxOriChanges];
	NSMutableArray			*stimList;
	BOOL					stimulusOn;
	LLFixTarget				*targetSpot;
	BOOL					targetPresented;
}

- (void)doFixSettings;
- (void)doGabor0Settings;
- (void)doGabor1Settings;
- (void)doTargetSpotSettings;
- (void)presentStimSequence;
- (void)dumpStimList;
- (void)erase;
- (LLGabor *)gabor0;
- (LLGabor *)gabor1;
- (LLGabor *)gaborWithIndex:(long)index;
- (LLGabor *)initGaborWithPrefix:(NSString *)prefix achromaticFlag:(BOOL)achromatic;
- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
- (void)makeStimList:(TrialDesc *)pTrial;
- (LLIntervalMonitor *)monitor;
- (void)setFixSpot:(BOOL)state;
- (void)shuffleStimListFrom:(short)start count:(short)count;
- (void)startStimSequence;
- (BOOL)stimulusOn;
- (void)stopAllStimuli;
- (BOOL)targetPresented;

@end
