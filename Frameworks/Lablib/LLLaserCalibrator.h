//
//  LLLaserCalibrator.h
//  Lablib
//
//  Created by John Maunsell on 10/29/08.
//  Copyright 2008. All rights reserved.
//


@interface LLLaserCalibrator : NSWindowController <NSWindowDelegate> {

	IBOutlet NSArrayController	*arrayController;
	IBOutlet NSTableView		*calibrationTable;
	NSArray						*sortArray;
	NSUserDefaults				*taskDefaults;
}

- (float)calibratedValueFor:(float)inputMW;
- (void)doDialog;
- (void)getValuesForCalibrationIndex:(long)index voltagePtr:(float *)pV mWPtr:(float *)pMW;
- (IBAction)insertRow:(id)sender;
- (float)maximumMW;
- (float)minimumMW;
- (IBAction)ok:(id)sender;
- (void)setDefaults:(NSUserDefaults *)newDefaults;

@end
