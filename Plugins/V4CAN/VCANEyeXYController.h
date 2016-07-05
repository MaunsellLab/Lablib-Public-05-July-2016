//
//  VCANEyeXYController.h
//  V4CAN
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStateSystem.h"

@interface VCANEyeXYController : NSWindowController <LLDrawable> {

	NSBezierPath			*calBezierPath[kEyes];
	NSPoint					currentEyeDeg[kEyes];
 	NSAffineTransform		*degToUnits[kEyes];
	NSMutableData			*eyeXSamples[kEyes];
	NSMutableData			*eyeYSamples[kEyes];
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inRespWindow[kStimLocs];
	BOOL					inTrial;
	BOOL					inWindow;
	NSColor					*respWindowColor;
	NSRect					respWindowRectDeg[kStimLocs];
	NSLock					*sampleLock;
	TrialDesc				trial;
 	NSAffineTransform		*unitsToDeg[kEyes];
   
    IBOutlet LLEyeXYView 	*eyePlot;
    IBOutlet NSNumberFormatter *filterFormatter;
    IBOutlet NSScrollView 	*scrollView;
    IBOutlet NSSlider		*slider;
    IBOutlet NSPanel		*optionsSheet;
}

- (IBAction)centerDisplay:(id)sender;
- (IBAction)changeZoom:(id)sender;
- (IBAction)doOptions:(id)sender;
- (IBAction)endOptionSheet:(id)sender;

- (void)deactivate;
- (void)processEyeSamplePairs:(long)eyeIndex;
- (void)setEyePlotValues;
- (void)setScaleFactor:(double)factor;
- (void)updateEyeCalibration:(long)eyeIndex eventData:(NSData *)eventData;

@end
