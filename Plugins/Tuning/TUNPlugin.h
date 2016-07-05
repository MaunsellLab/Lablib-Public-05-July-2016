//
//  TUNPlugin.h
//  Tuning
//
//  Copyright 2006. All rights reserved.
//

#import "TUN.h"
#import "TUNStateSystem.h"
#import "TUNEyeXYController.h"

@interface TUNPlugin:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyeUnits;
    TUNEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSWindowController 		*xtController;

    IBOutlet NSMenu				*actionsMenu;
 	IBOutlet NSMenuItem			*runStopMenuItem;
	IBOutlet NSMenu				*settingsMenu;
	IBOutlet NSArrayController	*stimController;
	IBOutlet NSArrayController	*testController;
	IBOutlet NSTextField		*valuesString;
}

- (IBAction)do360DegTest:(id)sender;
- (IBAction)doCueSettings:(id)sender;
- (IBAction)doFixSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (IBAction)doStimSettings:(id)sender;
- (void)loadTestParams;
- (TUNStimuli *)stimuli;
- (NSString *)valuesString;

@end
