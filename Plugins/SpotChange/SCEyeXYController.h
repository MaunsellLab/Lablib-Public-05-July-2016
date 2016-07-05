//
//  SCEyeXYController.h
//  SpotChange
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCStateSystem.h"

@interface SCEyeXYController : NSWindowController <LLDrawable> {

	NSBezierPath			*calBezierPath[kEyes];
//	NSColor					*calColor[kEyes];
	NSPoint					currentEyeDeg[kEyes];
 	NSAffineTransform		*degToUnits[kEyes];
	NSMutableData			*eyeXSamples[kEyes];
	NSMutableData			*eyeYSamples[kEyes];
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inRespWindow;
	BOOL					inTrial;
	BOOL					inWindow;
	NSColor					*respWindowColor;
	long					respWindowIndex;
	NSRect					respWindowRectDeg;
	NSLock					*sampleLock;
	TrialDesc				trial;
 	NSAffineTransform		*unitsToDeg[kEyes];
 	NSRect					wrongWindowRectDeg;
  
    IBOutlet LLEyeXYView 	*eyePlot;
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
