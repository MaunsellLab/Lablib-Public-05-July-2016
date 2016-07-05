/*
MTCStimuli.h
*/

#import "MTC.h"

@interface MTCStimuli : NSObject {

	LLGabor 				*nGabor;
	LLGabor 				*pGabor;
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
	short					selectTable[kMaxContrasts];
	NSMutableArray			*stimList;
	BOOL					stimulusOn;
	BOOL					targetPresented;
}

- (void)doCueSettings;
- (void)doFixSettings;
- (void)doGaborSettings;
- (void)presentStimList;
- (void)dumpStimList;
- (void)erase;
- (LLGabor *)gabor;
- (LLGabor *)initGabor;
- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial 
				type0:(short)type0 type1:(short)type1 contrastIndex:(short)cIndex;
- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
- (void)makeStimList:(TrialDesc *)pTrial;
- (LLIntervalMonitor *)monitor;
- (short)randomHighContrastIndex:(short)contrasts;
- (short)randomVisibleContrastIndex:(short)contrasts;
- (void)setCueSpot:(BOOL)state location:(long)loc;
- (void)setFixSpot:(BOOL)state;
- (void)shuffleStimListFrom:(short)start count:(short)count;
- (void)startStimList;
- (BOOL)stimulusOn;
- (void)stopAllStimuli;
- (void)tallyStimuli;
- (BOOL)targetPresented;

@end
