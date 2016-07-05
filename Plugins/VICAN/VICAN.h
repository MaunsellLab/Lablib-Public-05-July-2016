//
//  VICAN.h
//  VICAN
//
//  Copyright 2012. All rights reserved.
//

#import "VI.h"
#import "VIStateSystem.h"
#import "VIEyeXYController.h"
#import "VIDigitalOut.h"


@interface VICAN:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyesUnits[kEyes];
    VIEyeXYController		*eyeXYController;				// Eye position display
    NSWindowController 		*psychController;
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSArray                 *topLevelObjects;
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
- (IBAction)doStimSettings:(id)sender;
- (IBAction)doTargetSpotSettings:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (void)doRewardAverage:(NSString *)averageString;
- (void)doRewardTrial:(NSString *)trialString;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (IBAction)doStaircaseReset:(id)sender;
- (VIStimuli *)stimuli;
- (void)updateChangeAlphaTable:(NSString *)key;

@end
