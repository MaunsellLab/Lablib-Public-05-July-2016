//
//  LLTaskPlugIn.h
//  Lablib
//
//  Created by John Maunsell on 12/23/04.
//  Copyright 2004. All rights reserved.
//

#import "LLDataDoc.h"
#import "LLDisplays.h"
#import "LLBinocCalibrator.h"
#import "LLIODevice.h"
#import "LLDataDeviceController.h"
#import "LLMonitorController.h"
#import "LLStateSystem.h"
#import "LLStimWindow.h"
#import "LLSynthDataDevice.h"
#import  <Lablib/LLSynthIODevice.h>
#import "LLUserDefaults.h"

@interface LLTaskPlugIn : NSObject {

	BOOL					active;
	NSTimer					*collectorTimer;
	NSPoint					currentEyeDeg;
	NSPoint					currentEyesDeg[kEyes];
	LLDataDoc				*dataDoc;
	id<LLIODevice>          dataSource;
	LLDataDeviceController	*dataController;
	LLUserDefaults			*defaults;
	LLBinocCalibrator		*eyeCalibrator;
	id						host;
	BOOL					initialized;
    NSDate                  *lastDataCollectionDate;
	long					mode;
	LLMonitorController		*monitorController;
	DisplayModeParam		displayMode;
	LLStateSystem			*stateSystem;
	LLStimWindow			*stimWindow;
	LLSynthDataDevice		*synthDataDevice;
	LLSynthIODevice			*synthDataSource;
	BOOL					writingDataFile;
}

- (void)activate;
- (BOOL)active;
- (NSTimer *)collectorTimer;
- (NSPoint)currentEyeDeg;
- (NSPoint *)currentEyesDeg;
- (LLDataDeviceController *)dataController;
- (LLDataDoc *)dataDoc;
- (id<LLIODevice>)dataSource;
- (IBAction)deactivate:(id)sender;
- (LLUserDefaults *)defaults;
- (LLBinocCalibrator *)eyeCalibrator;
- (LLEyeCalibrator *)eyeLeftCalibrator;
- (LLEyeCalibrator *)eyeRightCalibrator;
- (BOOL)handleEvent:(NSEvent *)theEvent;
- (BOOL)handlesEvents;
- (BOOL)initialized;
- (void)initializationDidFinish;
- (NSDate *)lastDataCollectionDate;
- (long)mode;
- (LLMonitorController *)monitorController;
- (NSString *)name;
- (DisplayModeParam)requestedDisplayMode;
- (void)setDataDeviceController:(LLDataDeviceController *)controller;
- (void)setDataDocument:(LLDataDoc *)doc;
- (void)setDataSource:(id<LLIODevice>)source;
- (void)setDefaults:(LLUserDefaults *)newDefaults;
- (void)setEyeCalibrator:(LLBinocCalibrator *)calibrator;
- (void)setHost:(id)newHost;
- (void)setInitialized:(BOOL)state;
- (void)setLastDataCollectionDate:(NSDate *)newDate;
- (void)setMode:(long)mode;
- (void)setMonitorController:(LLMonitorController *)controller;
- (void)setWritingDataFile:(BOOL)state;
- (void)setStimWindow:(LLStimWindow *)newStimWindow;
- (void)setSynthDataDevice:(LLSynthDataDevice *)device;
- (void)setSynthDataSource:(LLSynthIODevice *)source;
- (LLStateSystem *)stateSystem;
- (LLStimWindow *)stimWindow;
- (LLSynthDataDevice *)synthDataDevice;
- (LLSynthIODevice *)synthDataSource;
- (BOOL)writingDataFile;

@end