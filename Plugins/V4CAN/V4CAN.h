//
//  V4CAN.h
//  V4CAN
//
//  Copyright 2012. All rights reserved.
//

#import "VCAN.h"
#import "VCANStateSystem.h"
#import "VCANEyeXYController.h"
#import "VCANDigitalOut.h"


@interface V4CAN:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyesUnits[kEyes];
    VCANEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSWindowController 		*xtController;

    IBOutlet NSMenu			*actionsMenu;
    IBOutlet NSMenu			*settingsMenu;
	IBOutlet NSTextField	*rewardAverageField;
	IBOutlet NSTextField	*rewardTrialField;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (IBAction)doCueSettings:(id)sender;
- (IBAction)doGaborSettings:(id)sender;
- (IBAction)doFixSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (IBAction)doTargetSpotSettings:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (void)doRewardAverage:(NSString *)averageString;
- (void)doRewardTrial:(NSString *)trialString;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (IBAction)doStaircaseReset:(id)sender;
- (VCANStimuli *)stimuli;

@end
