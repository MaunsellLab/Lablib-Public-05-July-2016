//
//  KNAppController.h
//  Knot
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003-2007. All rights reserved.
//
#import <Appkit/NSApplication.h>
#import "KNSummaryController.h"

@interface KNAppController : NSApplication <NSApplicationDelegate> {

	NSWindowController		*aboutPanel;					// About this application panel 
    LLTaskPlugIn 			*currentTask;
    
	LLDataDoc				*dataDoc;						// LLDataDoc for data events
	id<LLIODevice>			dataSource;
	LLUserDefaults			*defaults;
	LLDataDeviceController	*dataDeviceController;
	LLBinocCalibrator		*eyeCalibration;
	BOOL					initialized;
	LLMouseDataDevice		*mouseDataDevice;
	LLMonitorController		*monitorController;
	LLPluginController		*pluginController;
	LLSettingsController	*settingsController;
	LLStimWindow			*stimWindow;
    KNSummaryController		*summaryController;
	LLSynthDataDevice		*synthDataDevice;
	
	IBOutlet NSMenuItem		*recordDontRecordMenuItem;		// Menu item for recording or not
	IBOutlet NSMenu			*taskMenu;
}

- (void)activateCurrentTask;
- (void)configurePlugins;
- (void)deactivateCurrentTask;
- (void)loadDataDevicePlugins;
- (void)postDataParamEvents;

- (IBAction)changeDataSource:(id)sender;
- (IBAction)changeSettings:(id)sender;
- (IBAction)doPluginController:(id)sender;
- (IBAction)doTaskMenu:(id)sender;
- (IBAction)recordDontRecord:(id)sender;
- (IBAction)showAboutPanel:(id)sender;
- (IBAction)showDisplayCalibratorPanel:(id)sender;
- (IBAction)showEyeCalibratorPanel:(id)sender;
- (IBAction)showReportPanel:(id)sender;

@end
