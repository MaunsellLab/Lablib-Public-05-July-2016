//
//  VTEyeXYController.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStateSystem.h"

@interface VTEyeXYController : NSWindowController <LLDrawable> {

@private
	NSBezierPath			*calBezierPath;
	NSColor					*calColor;
	NSPoint					currentEyeDeg;
 	NSAffineTransform		*degToUnits;
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inTrial;
	NSColor					*respWindowColor;
	NSRect					respWindowRectDeg[2];
    long 					samplesToSave;
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
- (void)setEyePlotValues;
- (void)setScaleFactor:(double)factor;

@end
