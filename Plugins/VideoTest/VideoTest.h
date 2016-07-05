//
//  VideoTest.h
//  VideoTest
//
//  Created by John Maunsell on January 21, 2005
//  Copyright 2005. All rights reserved.
//

#import "VT.h"
#import "VTStateSystem.h"
#import "VTEyeXYController.h"
	
BOOL					brokeDuringStim;

@interface VideoTest:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	BOOL					collectorActive;
	BOOL					collectorShouldTerminate;
	LLControlPanel			*controlPanel;
    VTEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*summaryController;
    NSWindowController 		*xtController;
	LLTaskStatus			*taskStatus;
    IBOutlet NSMenu			*settingsMenu;
    IBOutlet NSMenu			*actionsMenu;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (void)dataCollect:(NSTimer *)timer;
- (IBAction)doJuice:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (VTStimuli *)stimuli;

@end
