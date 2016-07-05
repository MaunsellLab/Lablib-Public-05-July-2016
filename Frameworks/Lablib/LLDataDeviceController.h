//
//  LLDataDeviceController.h
//  Lablib
//
//  Created by John Maunsell on 10/1/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDataDevice.h"
#import "LLDataAssignment.h"

typedef struct {
	NSString *name;
	NSString *deviceName;
	long channel;
	float timing;
	long device;
	long type;
} DataAssignment;

typedef struct {
	Str31 dataName;
	Str31 deviceName;
	long channel;
	float timing;
	long type;
} DataParam;

#define kMaxDevices			8
#define kMaxChannels		16

extern NSString *LLDataSourceKey;

/*
Assignments are stored in assignmentDict, one entry per assignment.  The keys are the
names of the assignments.  The object for each key is a NSArray.  Most of these NSArrays
have a single object, which is an encoded DataAssignment.  Grouped assignments (for 
samples) have multiple objects in the array, one for each channel.
*/ 

@interface LLDataDeviceController : NSWindowController {

	NSMutableDictionary		*assignmentDict;
	LLDataDevice			*dataSource;
	NSMutableArray			*dataDevices;
	NSUserDefaults			*defaults;
	NSMutableDictionary		*deviceDict;
	NSLock					*deviceLock;
	double					lastCollectionTimeS;
	double					minCollectionIntS;
	NSMutableArray			*sampleAssignments;
	NSMutableData			*sampleData[kMaxDevices][kMaxChannels];
	NSMutableArray			*timestampAssignments;
	NSMutableData			*timestampData[kMaxDevices][kMaxChannels];
	
	IBOutlet NSPopUpButton		*digitalInMenu;
	IBOutlet NSPopUpButton		*digitalOutMenu;
	IBOutlet NSPopUpButtonCell	*sampleDeviceMenu;
	IBOutlet NSTableView		*sampleTable;
	IBOutlet NSTableView		*timestampTable;
	IBOutlet NSPopUpButtonCell	*timestampDeviceMenu;
}

- (void)addDataDevice:(LLDataDevice *)newDevice;
- (NSArray *)allDataParam;
- (void)assignmentDialog;
- (void)assignDigitalInputDevice:(NSString *)deviceName;
- (void)assignDigitalOutputDevice:(NSString *)deviceName;
- (void)assignGroupedSampleData:(DataAssignment *)assignments groupCount:(long)count;
- (void)assignSampleData:(DataAssignment)assignment;
- (void)assignTimestampData:(DataAssignment)assignment;
- (void)assignToNullDevice:(LLDataAssignment *)assign;
- (void)changeDataAssignment:(NSMutableData **)oldDeviceData oldChannel:(long)oldChannel 
				newDeviceData:(NSMutableData **)newDeviceData newChannel:(long)newChannel;
- (void)configureDeviceWithIndex:(long)index;
- (void)contingentReadDataFromDevices:(BOOL)onlyIfEnabled;
- (NSData *)dataOfType:(NSString *)typeName;
- (LLDataDevice *)deviceWithName:(NSString *)name;
- (unsigned long)digitalInputBits;
- (void)digitalOutputBits:(unsigned long)bits;
- (void)digitalOutputBitsOff:(unsigned long)bits;
- (void)digitalOutputBitsOn:(unsigned long)bits;
- (void)enableDevicesAndChannels;
- (long)indexForDeviceName:(NSString *)name;
- (NSString *)nameOfDeviceForDataOfType:(NSString *)typeName;
- (void)readDataFromDevices;
- (BOOL)readDefaults:(LLDataAssignment *)assign pTiming:(float *)pTiming;
- (void)removeAllAssignments;
- (void)setDataEnabled:(NSNumber *)state;
- (void)setDefaults:(NSUserDefaults *)newDefaults;
- (void)setMinCollectionIntervalS:(long)newIntervalS;
- (void)startDevice;
- (void)stopDevice;
- (void)writeDefaults:(LLDataAssignment *)assign;

- (IBAction)changeDigitalInput:(id)sender;
- (IBAction)changeDigitalOutput:(id)sender;
- (IBAction)configureDataDevice:(id)sender;
- (IBAction)ok:(id)sender;

@end

