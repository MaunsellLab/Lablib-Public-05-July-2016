//
//  LLStandardDataEvents.h
//  Lablib
//
//  Created by John Maunsell on Sat May 31 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDataDoc.h" 

#define kLLEyeWindowEventDesc \
{{@"long",	@"index", 1, offsetof(FixWindowData, index)},\
{@"CGFloat",	@"windowDeg.origin.x", 1, offsetof(FixWindowData, windowDeg.origin.x)},\
{@"CGFloat",	@"windowDeg.origin.y", 1, offsetof(FixWindowData, windowDeg.origin.y)},\
{@"CGFloat",	@"windowDeg.size.width", 1, offsetof(FixWindowData, windowDeg.size.width)},\
{@"CGFloat",	@"windowDeg.size.height", 1, offsetof(FixWindowData, windowDeg.size.height)},\
{@"CGFloat",	@"windowUnits.origin.x", 1, offsetof(FixWindowData, windowUnits.origin.x)},\
{@"CGFloat",	@"windowUnits.origin.y", 1, offsetof(FixWindowData, windowUnits.origin.y)},\
{@"CGFloat",	@"windowUnits.size.width", 1, offsetof(FixWindowData, windowUnits.size.width)},\
{@"CGFloat",	@"windowUnits.size.height", 1, offsetof(FixWindowData, windowUnits.size.height)},\
{nil}}

typedef struct {
	short channel;								// spike channel
    long time;									// spike time
} TimestampData;

typedef struct {	
	short channel;								// spike channel
    short data;									// channel data
} ADData;

typedef struct {	
	short device;								// data device index
	short channel;								// spike channel
    long time;									// spike time
} DeviceTimestampData;

typedef struct {	
	short device;								// data device index
	short channel;								// spike channel
    short data;									// channel data
} DeviceADData;

typedef struct {	
	short device;								// data device index
	short channel;								// data channel
    long count;									// number of samples or timestamps
} DeviceDataHeader;

typedef struct {
    long	index;								// window id
	NSRect	windowDeg;							// window in degrees
    NSRect	windowUnits;						// window in A/D eye units
} FixWindowData;

#define kLLEyeXChannel			0
#define kLLEyeYChannel			1

enum {kEOTCorrect = 0, kEOTWrong, kEOTFailed, kEOTBroke, kEOTIgnored, kEOTQuit, kEOTTypes} EOTType;
enum {kCertifyVideoBit = 0, kCertifyDataBit, kCertifyTypes} CertifyType;
enum {kTaskIdle, kTaskStopping, kTaskRunning, kTaskEnding, kTaskQuitting, kTaskModes} TaskMode;	// defines for state system modes
#define kLLFileOpen     0
#define kLLFileOpenBit	4
#define kLLFileOpenMask	(0x00000001 << kLLFileOpenBit)
#define kLLTaskModeMask	0x0000000f

#define kGuns			3

@interface LLStandardDataEvents : NSObject {

}

+ (long)count;
+ (long)countOfEventsWithDataDefs;
+ (NSColor *)eotColor:(long)index;
+ (EventDef *)events;
+ (EventDefinition *)eventsWithDataDefs;
+ (NSString *)trialEndName:(short)eotCode;
@end
