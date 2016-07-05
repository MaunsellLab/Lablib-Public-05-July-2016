//
//  LLSystemUtil.m
//  Lablib
//
//  Created by John Maunsell on Wed Jan 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSystemUtil.h"
#include <sys/sysctl.h>
#include <mach/mach_init.h> 
#include <mach/thread_policy.h> 
#include <mach/thread_act.h> 
#import <IOKit/pwr_mgt/IOPMLib.h>

static void preventSleepCallback(CFRunLoopTimerRef timer, void *info);

@implementation LLSystemUtil
// Find all bundles in any application support folder that end with a given extension

+ (NSMutableArray *)allBundlesWithExtension:(NSString *)extention appSubPath:(NSString *)appSubpath;
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
	NSDirectoryEnumerator *bundleEnum;
	NSString *currBundlePath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];

    librarySearchPaths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    searchPathEnum = [librarySearchPaths objectEnumerator];
    while (currPath = [searchPathEnum nextObject]) {
        [bundleSearchPaths addObject:
            [currPath stringByAppendingPathComponent:appSubpath]];
    }
    [bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];

    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while (currPath = [searchPathEnum nextObject]) {
        bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath];
        if (bundleEnum) {
            while (currBundlePath = [bundleEnum nextObject]) {
                if ([[currBundlePath pathExtension] isEqualToString:extention]) {
					[allBundles addObject:[currPath
                           stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
    return allBundles;
}

+ (long)busSpeedHz {

    int mib[2];
    unsigned int miblen;
    int busSpeed;
    size_t length;
    
    mib[0] = CTL_HW;
    mib[1] = HW_BUS_FREQ;
    miblen = 2;
    length = 4;
    sysctl(mib, miblen, &busSpeed, &length, NULL, 0);
    return busSpeed;
}

extern void CGSSetDebugOptions(int); 
extern void CGSDeferredUpdates(int);

+ (void)setBeamSynchronization:(long)mode;	// set beam synchronization (for 10.4)
{	
	CGSSetDebugOptions(mode ? 0 : 0x08000000);
	CGSDeferredUpdates(mode);
}

+ (NSString *)formattedDateString:(NSDate *)date format:(NSString *)format;
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:format];
    return [formatter stringFromDate:date];
}

+ (double)getTimeS {

    struct timeval tod;
	
    gettimeofday(&tod, NULL);
    return tod.tv_sec + tod.tv_usec * 1.0E-6;
}

+ (void)preventSleep {
	
	CFRunLoopTimerRef timer;
	CFRunLoopTimerContext context = {0, NULL, NULL, NULL, NULL};
		
	timer = CFRunLoopTimerCreate(NULL, CFAbsoluteTimeGetCurrent(), 30, 0, 0, preventSleepCallback, &context);
	if (timer != NULL) {
		CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes);
	}
}

+ (void)registerDefaultsFromFilePath:(NSString *)filePath defaults:(NSUserDefaults *)defaults;
{
    NSDictionary *userDefaultsValuesDict;
	
	userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	if (userDefaultsValuesDict == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                        @"registerDefaultsFromFileName: Failed to parse file \"%@\"", filePath]];
//		NSRunAlertPanel(@"LLSystemUtil", @"registerDefaultsFromFileName: Failed to parse file \"%@\"",
//						@"OK", nil, nil, filePath);
		exit(0);
	}
	[defaults registerDefaults:userDefaultsValuesDict];
}

// Create and run an alert panel

+ (void)runAlertPanelWithMessageText:(NSString *)messageText informativeText:(NSString *)infoText
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    
    [theAlert setMessageText:messageText];
    [theAlert setInformativeText:infoText];
    [theAlert runModal];
    [theAlert release];
}

// Set the current (calling) thread's priority for real time performance.  The periodMS argument
// gives the lenght of the periods over which real time performance is evaluated (e.g., one video
// frame).  The computationFraction argument specifies the fraction of the period for which the 
// thread wants to hold the CPU.  The constraintFraction argument specifies the maximum fraction
// of the period during which the computationFraction must occur.

+ (BOOL)setThreadPriorityPeriodMS:(float)periodMS computationFraction:(float)computationFraction
							constraintFraction:(float)constraintFraction {

	struct thread_time_constraint_policy TTCPolicy; 
    long result; 
	long busSpeedHz = [LLSystemUtil busSpeedHz];

	computationFraction = MIN(MAX(0.0, computationFraction), 1.0);
	constraintFraction = MIN(MAX(0.0, constraintFraction), 1.0);
	constraintFraction = MAX(constraintFraction, computationFraction);
    TTCPolicy.period = busSpeedHz * periodMS / 1000.0;					// HZ/n 
    TTCPolicy.computation = TTCPolicy.period * computationFraction;		// HZ/n; 
    TTCPolicy.constraint = TTCPolicy.period * constraintFraction;		// HZ/n; 
    TTCPolicy.preemptible = YES; 
	
	result = thread_policy_set(mach_thread_self(), THREAD_TIME_CONSTRAINT_POLICY, 
		(int *)&TTCPolicy,  THREAD_TIME_CONSTRAINT_POLICY_COUNT);
	return (result == KERN_SUCCESS); 
}

+ (NSTimeInterval)timeFromNow:(long)timeMS {

	return ([NSDate timeIntervalSinceReferenceDate] + timeMS / 1000.0);
}

+ (BOOL)timeIsPast:(NSTimeInterval)time {

	return ([NSDate timeIntervalSinceReferenceDate]  >= time);
}


static void preventSleepCallback(CFRunLoopTimerRef timer, void *info) {
 
    IOPMAssertionID assertionID;
    CFStringRef reasonForActivity= CFSTR("Collecting Data");
    
    IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn,
                                               reasonForActivity, &assertionID);
//    UpdateSystemActivity(OverallAct);
}


@end
