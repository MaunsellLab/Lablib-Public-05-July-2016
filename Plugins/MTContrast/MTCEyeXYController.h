//
//  MTCEyeXYController.h
//  MTContrast
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCStateSystem.h"

@interface MTCEyeXYController : NSWindowController <LLDrawable> {

	NSBezierPath			*calBezierPath;
	NSColor					*calColor;
	NSPoint					currentEyeDeg;
 	NSAffineTransform		*degToUnits;
	NSMutableData			*eyeXSamples;
	NSMutableData			*eyeYSamples;
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inRespWindow[2];
	BOOL					inTrial;
	BOOL					inWindow;
	NSColor					*respWindowColor;
	NSRect					respWindowRectDeg[2];
	NSLock					*sampleLock;
	TrialDesc				trial;
 	NSAffineTransform		*unitsToDeg;
   
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
- (void)processEyeSamplePairs;
- (void)setEyePlotValues;
- (void)setScaleFactor:(double)factor;

@end
