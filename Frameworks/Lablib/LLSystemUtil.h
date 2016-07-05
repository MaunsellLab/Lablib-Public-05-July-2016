//
//  LLSystemUtil.h
//  Lablib
//
//  Created by John Maunsell on Wed Jan 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import <sys/time.h>

typedef enum {
	kDisableBeamSync = 0,
	kAutomaticBeamSync = 1,
	kForcedBeamSyncMode = 2
} BeamSyncMode;

typedef enum {
	kLLLeftMouseDown = 0x1,
	kLLRightMouseDown = 0x2,
	kLLOtherMouseDown = 0x4
} LLMouseButtonDown;

@interface LLSystemUtil : NSObject {

}

+ (NSMutableArray *)allBundlesWithExtension:(NSString *)extention appSubPath:(NSString *)appSubpath;
+ (long)busSpeedHz;							// Return the speed of the system bus in Hz
+ (void)setBeamSynchronization:(long)mode;	// set beam synchronization (for 10.4)
+ (NSString *)formattedDateString:(NSDate *)date format:(NSString *)format;
+ (double)getTimeS;							// Return the system time in seconds as a double
+ (void)preventSleep;							// Stop the computer from sleeping
+ (void)registerDefaultsFromFilePath:(NSString *)filePath defaults:(NSUserDefaults *)defaults;
+ (void)runAlertPanelWithMessageText:(NSString *)messageText informativeText:(NSString *)infoText;
+ (BOOL)setThreadPriorityPeriodMS:(float)periodMS computationFraction:(float)computationFraction
							constraintFraction:(float)constraintFraction;
+ (NSTimeInterval)timeFromNow:(long)timeMS;
+ (BOOL)timeIsPast:(NSTimeInterval)time;

@end
