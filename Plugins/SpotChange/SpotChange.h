//
//  SpotChange.h
//  SpotChange
//
//  Copyright 2006. All rights reserved.
//

#import "SC.h"
#import "SCStateSystem.h"
#import "SCEyeXYController.h"
#import "SCRoundToStimCycle.h"
#import "SCDigitalOut.h"

@interface SpotChange:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyesUnits[kEyes];
    SCEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSArray                 *topLevelObjects;
    NSWindowController 		*xtController;

    IBOutlet NSMenu			*actionsMenu;
    IBOutlet NSMenu			*settingsMenu;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (IBAction)doGabor0Settings:(id)sender;
- (IBAction)doGabor1Settings:(id)sender;
- (IBAction)doFixSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (IBAction)doTargetSpotSettings:(id)sender;

- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (SCStimuli *)stimuli;
- (void)updateChangeTable;

@end
