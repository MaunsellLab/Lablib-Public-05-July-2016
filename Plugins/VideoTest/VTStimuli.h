/*
VTStimuli.h
*/

@interface VTStimuli : NSWindow {

@public
	LLGabor 				*gabor;
@protected
	double					contrast;
	DisplayParam			display;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	LLIntervalMonitor 		*monitor;
	BOOL					stimulusOn;
	LLFixTarget				*targetSpot0;
	LLFixTarget				*targetSpot1;
}

- (DisplayParam *)displayParameters;
- (void)doStimulusPresentation;
- (void)erase;
- (LLIntervalMonitor *)monitor;
- (void)runContrast:(double)stimContrast duration:(long)stimDurationMS;
- (void)setFixSpot:(BOOL)state;
- (void)setTargets:(BOOL)state contrast0:(long)contrast0 contrast1:(long)contrast1;
- (BOOL)stimulusOn;

@end
