//
//  MTContrast.h
//  MTContrast
//
//  Copyright 2006. All rights reserved.
//

#import "MTC.h"
#import "MTCStateSystem.h"
#import "MTCEyeXYController.h"

@interface MTContrast:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyeUnits;
    MTCEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSWindowController 		*xtController;

    IBOutlet NSMenu			*actionsMenu;
    IBOutlet NSMenu			*settingsMenu;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (IBAction)doCueSettings:(id)sender;
- (IBAction)doGaborSettings:(id)sender;
- (IBAction)doFixSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (MTCStimuli *)stimuli;

@end
