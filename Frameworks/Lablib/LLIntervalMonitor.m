//
//  LLIntervalMonitor.m
//  Lablib
//
//  Created by John Maunsell on Wed Jan 29 2003.
//  Copyright (c) 2003. All rights reserved.
//
// GMG 
//	modified so that when interval is set, less than and greater than alarms match interval
//  bug fix regarding display of minrangeMS in valueString
//  removed warnGreaterMSKey and warnLessMSKey (weren't being used)
//  panel modified to display correct interval with setInterval is used

#import "LLIntervalMonitor.h"
#import "LLSystemUtil.h"

#define kRangeMinLimitS	-0.010
#define kRangeMaxLimitS	0.010

NSString *doSuccessGreaterKey = @"LLDoSuccessGreater";
NSString *doSuccessLessKey = @"LLDoSuccessLess";
NSString *doWarnDisarmKey = @"LLDoWarnDisarm";
NSString *doWarnGreaterKey = @"LLDoWarnGreater";
NSString *doWarnLessKey = @"LLDoWarnLess";
NSString *doWarnSequentialKey = @"LLDoWarnSequential";
NSString *successLessCountKey = @"LLSuccessLessCount";
NSString *successLessMSKey = @"LLSuccessLessS";
NSString *successGreaterCountKey = @"LLSuccessGreaterCounter";
NSString *successGreaterMSKey = @"LLSuccessGreaterS";
NSString *warnGreaterCountKey = @"LLWarnGreaterCount";
NSString *warnLessCountKey = @"LLWarnLessCount";
NSString *warnSequentialCountKey = @"LLWarnSequentialCount";
NSString *standardKey = @"LLMonitorTarget";

@implementation LLIntervalMonitor

- (void)checkWarnings;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (alarmActive || [defaults boolForKey:[self uniqueKey:doWarnDisarmKey]]) {
		return;
	}
	if ([defaults boolForKey:[self uniqueKey:doWarnGreaterKey]]) {
		if (greaterFailures >= [defaults integerForKey:[self uniqueKey:warnGreaterCountKey]]) {
			[self doAlarm:[NSString stringWithFormat:@"Warning: %ld intervals %.1f ms greater than average.",
				greaterFailures, cumulativeValues.rangeMaxMS]];
			greaterFailures = 0;
			return;
		}
	}
	if ([defaults boolForKey:[self uniqueKey:doWarnLessKey]]) {
		if (lessFailures >= [defaults integerForKey:[self uniqueKey:warnLessCountKey]]) {
			[self doAlarm:[NSString stringWithFormat:@"Warning: %ld intervals %.1f ms less than average.",
				lessFailures, cumulativeValues.rangeMinMS]];
			lessFailures = 0;
			return;
		}
	}
	if ([defaults boolForKey:[self uniqueKey:doWarnSequentialKey]]) {
		if (sequentialFailures >= [defaults integerForKey:[self uniqueKey:warnSequentialCountKey]]) {
			[self doAlarm:[NSString stringWithFormat:@"Warning: %ld sequences in a row have failed.",
				sequentialFailures]];
			sequentialFailures = 0;
			return;
		}
	}
}

- (void)configure;
{
	[settings showWindow:self];
}

- (void)dealloc;
{
	[descriptionString release];
	[IDString release];
	[settings release];
	[times release];
	[super dealloc];
}

- (void)doAlarm:(NSString *)message;
{
	long choice;
    NSAlert *theAlert;
	
	alarmActive = YES;
    theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:[NSString stringWithFormat:@"LLIntervalMonitor (%@)", [self IDString]]];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert addButtonWithTitle:@"Disarm Alarms"];
    [theAlert addButtonWithTitle:@"Change Settings"];
//    theAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"LLIntervalMonitor (%@)", [self IDString]]
//                            defaultButton:@"OK" alternateButton:@"Disarm Alarms" otherButton:@"Change Settings"
//                            informativeTextWithFormat:@""];
	choice = [theAlert runModal];
	switch (choice) {
	case NSAlertSecondButtonReturn:						// disarm alarms
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[self uniqueKey:doWarnDisarmKey]];
		break;
	case NSAlertThirdButtonReturn:
		[self configure];								// configure alarms
		break;
	case NSAlertFirstButtonReturn:						// OK button, do nothing
	default:
		break;
	}
	alarmActive = NO;
    [theAlert release];
}

- (NSString *)IDString;
{
	return IDString;
}

- (id)initWithID:(NSString *)ID description:(NSString *)description;
{
    NSMutableDictionary *defaultSettings;

    if ((self = [super init]) != nil) {

// ID must be set up before doing the default settings

		[ID retain];
		IDString = ID;
		[description retain];
		descriptionString = description;
		times = [[NSMutableArray alloc] init];

// Set up all the default settings

		defaultSettings = [[NSMutableDictionary alloc] init];
		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:[self uniqueKey:doSuccessGreaterKey]];
		[defaultSettings setObject:[NSNumber numberWithInt:0] forKey:[self uniqueKey:successGreaterCountKey]];
		[defaultSettings setObject:[NSNumber numberWithFloat:10.0] forKey:[self uniqueKey:successGreaterMSKey]];

		[defaultSettings setObject:[NSNumber numberWithBool:NO] forKey:[self uniqueKey:doSuccessLessKey]];
		[defaultSettings setObject:[NSNumber numberWithInt:0] forKey:[self uniqueKey:successLessCountKey]];
		[defaultSettings setObject:[NSNumber numberWithFloat:10.0] forKey:[self uniqueKey:successLessMSKey]];

		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:[self uniqueKey:doWarnGreaterKey]];
		[defaultSettings setObject:[NSNumber numberWithInt:100] forKey:[self uniqueKey:warnGreaterCountKey]];

		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:[self uniqueKey:doWarnLessKey]];
		[defaultSettings setObject:[NSNumber numberWithInt:100] forKey:[self uniqueKey:warnLessCountKey]];

		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:[self uniqueKey:doWarnSequentialKey]];
		[defaultSettings setObject:[NSNumber numberWithInt:3] forKey:[self uniqueKey:warnSequentialCountKey]];
		
		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:[self uniqueKey:doWarnDisarmKey]];
		[defaultSettings setObject:@"mean" forKey:[self uniqueKey:standardKey]];

		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettings];
		[defaultSettings release];

// Default settings should be done before initializing values

		settings = [[LLIntervalMonitorSettings alloc] initWithID:IDString];
		[self initValues:&currentValues];
		[self initValues:&cumulativeValues];
		[self initValues:&lastValues];
		lastTimeMS = 0.0;
	}
    return self;
}

- (void)initValues:(MonitorValues *)pValues;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    pValues->n = pValues->sum = pValues->sumsq = 0.0;
    pValues->overRange = pValues->underRange = 0.0;
    pValues->minValue = 1e100;
    pValues->maxValue = -1e100;
	pValues->rangeMaxMS = [defaults floatForKey:[self uniqueKey:successGreaterMSKey]];
	pValues->rangeMinMS = [defaults floatForKey:[self uniqueKey:successLessMSKey]];
}

- (BOOL)isConfigurable;
{
	return YES;
}

// Record the occurence of an event.  This is the method that should be called 
// when the event being monitored occurs.

- (void)recordEvent;
{
    double currentTimeMS, deltaTimeMS, targetMS;
    
    currentTimeMS = [LLSystemUtil getTimeS] * 1000.0;			// get the time now
    if (lastTimeMS != 0) {
        deltaTimeMS = currentTimeMS - lastTimeMS;
		[times addObject:[NSNumber numberWithFloat:deltaTimeMS]];
		currentValues.n += 1.0;
		currentValues.sum += deltaTimeMS;
		currentValues.sumsq += deltaTimeMS * deltaTimeMS;
		currentValues.maxValue = MAX(currentValues.maxValue, deltaTimeMS);
		currentValues.minValue = MIN(currentValues.minValue, deltaTimeMS);
		targetMS = (useTarget) ? targetIntervalMS : currentValues.sum / currentValues.n;
		if (deltaTimeMS > targetMS + currentValues.rangeMaxMS) {
			currentValues.overRange += 1.0;
		}
		if (deltaTimeMS < targetMS - currentValues.rangeMinMS) {
			currentValues.underRange += 1.0;
		}
    }
    lastTimeMS = currentTimeMS;
}

- (NSAttributedString *)report;
{
	long index;
	NSMutableString *textString;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	for (index = 0; index < [times count]; index++) {
		if ([[times objectAtIndex:index] floatValue] > 30) {
			NSLog(@"LLIntervalMonitor %ld %.0f", index, [[times objectAtIndex:index] floatValue]);
		}
	}
	
	textString = [[[NSMutableString alloc] initWithString:descriptionString] autorelease];

	if (sequenceCount == 0) {
		[textString appendString:@"\n\n(No interval sequences have been completed)"];
	}
	else {
		[textString appendString:[NSString stringWithFormat:@"\n\n%ld interval sequences have been completed", 
			sequenceCount]];
		
		if (greaterFailures == 0) {
			[textString appendString:@"\n    None"];
		}
		else {
			[textString appendString:[NSString stringWithFormat:@"\n    %ld", greaterFailures]];
		}
		[textString appendString:[NSString stringWithFormat:
				@" failed owing to more than %ld intervals %.1f ms > ",
				(long)[defaults integerForKey:[self uniqueKey:successGreaterCountKey]],
				currentValues.rangeMaxMS]];
		[textString appendString:(useTarget) ?
				[NSString stringWithFormat:@"%.1f", targetIntervalMS] : @"mean"];
		if (lessFailures == 0) {
			[textString appendString:@"\n    None"];
		}
		else {
			[textString appendString:[NSString stringWithFormat:@"\n    %ld", lessFailures]];
		}
		[textString appendString:[NSString stringWithFormat:
				@" failed owing to more than %ld intervals %.1f ms < ",
				(long)[defaults integerForKey:[self uniqueKey:successLessCountKey]],
				currentValues.rangeMinMS]];
		[textString appendString:(useTarget) ?
				[NSString stringWithFormat:@"%.1f", targetIntervalMS] : @"mean"];

		if (lastValues.n > 0) {
			[textString appendString:@"\n\n   Last Sequence: "];
			[textString appendString:[self valueString:&lastValues]];
		}
		[textString appendString:@"\n   All Sequences: "];
		[textString appendString:[self valueString:&cumulativeValues]];
	}
	return [[[NSAttributedString alloc] initWithString:textString] autorelease];
}

// Reset clears the counters for a new sequence, but this is also the event that
// causes cumulative values to get incremented and tests for warnings to be run

- (void)reset;
{
	[times removeAllObjects];
	if (currentValues.n > 0) {							// update the cumulative values
		cumulativeValues.n += currentValues.n;
		cumulativeValues.sum += currentValues.sum;
		cumulativeValues.sumsq += currentValues.sumsq;
		cumulativeValues.maxValue = MAX(currentValues.maxValue, cumulativeValues.maxValue);
		cumulativeValues.minValue = MIN(currentValues.minValue, cumulativeValues.minValue);
		cumulativeValues.overRange += currentValues.overRange;
		cumulativeValues.underRange += currentValues.underRange;
		sequenceCount++;
	}
	lastValues = currentValues;							// save for reporting
	[self initValues:&currentValues];					// clear for the next period
    lastTimeMS = 0.0;
	[[NSNotificationCenter defaultCenter] postNotificationName:LLMonitorUpdated object:self];
	[self checkWarnings];
}

- (void)setTargetIntervalMS:(double)intervalMS;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	targetIntervalMS = intervalMS;
	useTarget = (targetIntervalMS > 0);
	if(useTarget) {
		[defaults setObject:[NSNumber numberWithFloat:targetIntervalMS] forKey:[self uniqueKey:successGreaterMSKey]];
		[defaults setObject:[NSNumber numberWithFloat:targetIntervalMS] forKey:[self uniqueKey:successLessMSKey]];
		cumulativeValues.rangeMaxMS=currentValues.rangeMaxMS=targetIntervalMS;
		cumulativeValues.rangeMinMS=currentValues.rangeMinMS=targetIntervalMS;
		[defaults setObject:[NSString stringWithFormat:@"%.1f",targetIntervalMS] forKey:[self uniqueKey:standardKey]];
	}
}

- (BOOL)success;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL result;
	
	if (lastValues.n == 0) {
		sequentialFailures = 0;
		return YES;
	}
	result = YES;
    if ([defaults boolForKey:[self uniqueKey:doSuccessGreaterKey]]) {
		if (lastValues.overRange > [defaults boolForKey:[self uniqueKey:successGreaterCountKey]]) {
			greaterFailures++;
			result = NO;
		}
	}
    if ([defaults boolForKey:[self uniqueKey:doSuccessLessKey]]) {
		if (lastValues.underRange > [defaults boolForKey:[self uniqueKey:successLessCountKey]]) {
			lessFailures++;
			result = NO;
		}
	}
	sequentialFailures = (result) ? 0: sequentialFailures + 1;
	return result;
}

- (NSString *)valueString:(MonitorValues *)pValues;
{
	return [NSString  stringWithFormat:
		@"n = %.0lf mean = %.1lf max = %.1lf (%.0lf %.1lf > %@) min = %.1lf (%.0lf %.1lf < %@)", 
		pValues->n, pValues->sum / pValues->n, pValues->maxValue, pValues->overRange,
		pValues->rangeMaxMS, 
		(useTarget) ? [NSString stringWithFormat:@"%.1f", targetIntervalMS] : @"mean",
		pValues->minValue, pValues->underRange, pValues->rangeMinMS,
		(useTarget) ? [NSString stringWithFormat:@"%.1f", targetIntervalMS] : @"mean"];
}

// Because there may be many instances of some objects, we save using keys that are made
// unique by prepending the IDString

- (NSString *)uniqueKey:(NSString *)commonKey;
{
	return [NSString stringWithFormat:@"%@ %@", IDString, commonKey]; 
}

@end
