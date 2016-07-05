//
//  RFMap.h
//  RFMap
//
//  Created by John Maunsell on 12/30/04.
//  Copyright 2004. All rights reserved.
//

#import "RF.h"
#import "RFSummaryController.h"
#import "RFStateSystem.h"
#import "RFEyeXYController.h"

@interface RFMap:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
	LLControlPanel			*controlPanel;
	NSTimer					*displayTimer;
    RFEyeXYController		*eyeXYController;				// Eye position display
	float					originalFixOffsetDeg;			// holds incoming fix offset
	NSMenuItem				*settingsMenuItem;
    RFSummaryController		*summaryController;
	LLTaskStatus			*taskStatus;
    NSArray                 *topLevelObjects;
    NSWindowController 		*xtController;

    IBOutlet NSMenu			*settingsMenu;
    IBOutlet NSMenu			*actionsMenu;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (void)dataCollect:(NSTimer *)timer;
- (void)displayPosition:(NSTimer*)theTimer;
- (void)doJuiceOff;
- (RFMapStimuli *)stimuli;

- (IBAction)doFixSettings:(id)sender;
- (IBAction)doStimSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (IBAction)doReset:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (IBAction)postPosition:(id)sender;

@end
