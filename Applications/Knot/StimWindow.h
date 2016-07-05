/*
StimWindow.h
*/

@interface StimWindow : NSWindow {

@public
	LLGabor 				*gabor;

@protected
	double					contrast;
	DisplayParam			display;
	long					displayIndex;
	LLDisplays				*displays;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	BOOL					fullscreen;
	LLIntervalMonitor 		*monitor;
	NSLock					*openGLLock;
	NSOpenGLContext 		*stimOpenGLContext;
	LLFixTarget				*targetSpot0;
	LLFixTarget				*targetSpot1;
}

- (NSPoint)centerPointPix;
- (DisplayParam *)displayParameters;
- (void)doStimulusPresentation;
- (void)erase;
- (LLIntervalMonitor *)monitor;
- (void)runContrast:(double)stimContrast duration:(long)stimDurationMS;
- (void)setFixSpot:(BOOL)state;
- (void)setScaling;
- (void)setTargets:(BOOL)state contrast0:(long)contrast0 contrast1:(long)contrast1;
- (void)showDisplayParametersPanel;

@end
