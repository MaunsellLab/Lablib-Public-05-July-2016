//
//  LLDataDeviceController.m
//  Lablib
//
//  Created by John Maunsell on 10/1/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDataDeviceController.h"
#import "LLNullDataDevice.h" 
#import "LLSystemUtil.h"

enum {kLLDeviceName, kLLChannelIndex, kLLRateIndex};

NSString *LLDataAssignmentKey = @"LLDataAssignment";
NSString *LLDataDeviceDigitalInKey = @"LLDataDeviceDigitalIn";
NSString *LLDataDeviceDigitalOutKey = @"LLDataDeviceDigitalOut";

@implementation LLDataDeviceController

- (void)addDataDevice:(LLDataDevice *)newDevice;
{
	[newDevice setDeviceIndex:[dataDevices count]];
	[newDevice setController:self];
	[dataDevices addObject:newDevice];
	[deviceDict setObject:newDevice forKey:[newDevice name]];
	[sampleDeviceMenu addItemWithTitle:[newDevice name]];
	[timestampDeviceMenu addItemWithTitle:[newDevice name]];
	[digitalInMenu addItemWithTitle:[newDevice name]];
	[digitalOutMenu addItemWithTitle:[newDevice name]];
}

// Return an array of DataParms that describe the current data assignments

- (NSArray *)allDataParam;
{
	NSString *key;
	DataParam param;
	LLDataAssignment *assign;
	LLDataDevice *theDevice;
	NSArray *assignArray;
	NSEnumerator *enumerator, *arrayEnum;
	NSArray *keys = [assignmentDict allKeys];
	NSMutableArray *paramArray = [NSMutableArray arrayWithCapacity:0];
	
	enumerator = [keys objectEnumerator];
	while (key = [enumerator nextObject]) {
		assignArray = [assignmentDict objectForKey:key];
		arrayEnum = [assignArray objectEnumerator];
		while (assign = [arrayEnum nextObject]) {
			theDevice = [dataDevices objectAtIndex:[assign device]];
			[key getCString:(char *)&param.dataName 
						maxLength:(sizeof(Str31) - 1) encoding:NSUTF8StringEncoding];
			[[theDevice name] getCString:(char *)&param.deviceName 
						maxLength:(sizeof(Str31) - 1) encoding:NSUTF8StringEncoding];
			param.channel = [assign channel];
			param.type = [assign type];
			if (param.type == kLLSampleData) {
				param.timing = [theDevice samplePeriodMSForChannel:param.channel];
			}
			else {
				param.timing = [theDevice timestampPeriodMSForChannel:param.channel];
			}
			[paramArray addObject:[NSValue valueWithBytes:&param objCType:@encode(DataParam)]];
		}
	}
	return ([paramArray count] == 0) ? nil : paramArray;
}

- (void)assignmentDialog;
{
	[dataDevices makeObjectsPerformSelector:@selector(setDeviceEnabled:) 
							withObject:[NSNumber numberWithBool:NO]];
	[dataDevices makeObjectsPerformSelector:@selector(disableAllChannels)];
	[digitalInMenu selectItemAtIndex:
		[self indexForDeviceName:[defaults stringForKey:LLDataDeviceDigitalInKey]]];
	[digitalOutMenu selectItemAtIndex:
		[self indexForDeviceName:[defaults stringForKey:LLDataDeviceDigitalOutKey]]];
	[sampleTable noteNumberOfRowsChanged];
	[timestampTable noteNumberOfRowsChanged]; 

	[NSApp runModalForWindow:[self window]];
	[[self window] orderOut:self];

	[self enableDevicesAndChannels];
}

- (void)assignDigitalInputDevice:(NSString *)deviceName;
{
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:deviceName
			forKey:LLDataDeviceDigitalInKey]];
}

- (void)assignDigitalOutputDevice:(NSString *)deviceName;
{
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:deviceName
			forKey:LLDataDeviceDigitalOutKey]];
}

- (void)assignGroupedData:(DataAssignment *)assignments groupCount:(long)count type:(long)dataType;
{
	long index;
	NSMutableArray *groupArray;
	LLDataDevice *device;
	LLDataAssignment *assign;
	DataAssignment *pAssign;

	[dataDevices makeObjectsPerformSelector:@selector(setDeviceEnabled:) 
							withObject:[NSNumber numberWithBool:NO]];
	[dataDevices makeObjectsPerformSelector:@selector(disableAllChannels)];
	[deviceLock lock];

// Check that there is a valid assignment name, and that it is consistent within the 
// entire group.  The first entry in the group must have a unique name, and other
// members must have the same name (or nil).

	for (index = 0, pAssign = assignments; index < count; index++, pAssign++) {
		pAssign->type = dataType;							// load the data type
		if (index == 0) {
			if (pAssign->name == nil) {						// must have a name
                [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDeviceController"
                                informativeText:@"Attempt to define data type with no name"];
//				NSRunAlertPanel(@"LLDataDeviceController",  
//							@"Attempt to define data type with no name", 
//							@"OK", nil, nil);
				exit(0);
			}
			if ([assignmentDict objectForKey:pAssign->name] != nil) {	// unique name
                [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDeviceController" informativeText:[NSString stringWithFormat:@"Attempt to define two types of sample data as \"%@\".", pAssign->name]];
//				NSRunAlertPanel(@"LLDataDeviceController",
//							@"Attempt to define two types of sample data as \"%@\".", 
//							@"OK", nil, nil, pAssign->name);
				exit(0);
			}
		}
		else {												// same name for whole group
			if (pAssign->name != nil && ![pAssign->name isEqualToString:assignments[0].name]) {
                [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDeviceController" informativeText:[NSString stringWithFormat:@"Member of grouped data given different name (\"%@\" instead of \"%@\")",
                            pAssign->name, assignments[0].name]];
//				NSRunAlertPanel(@"LLDataDeviceController",
//						@"Member of grouped data given different name (\"%@\" instead of \"%@\")", 
//						@"OK", nil, nil, pAssign->name, assignments[0].name);
				exit(0);
			}
			if (dataType != kLLSampleData) {				// only sample data can be grouped
                [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDeviceController"
                                           informativeText:@"Attempt to group timestamp data"];
//				NSRunAlertPanel(@"LLDataDeviceController",
//						@"Attempt to group timestamp data", @"OK", nil, nil);
				exit(0);
			}
		}

// Before we can create the LLDataAssignment(s), we need to set the device index, based on
// the device name in the DataAssignment.  If the name does not map to an known device,
// the index reverts to the Null device.  Check that we have enough memory allocated to
// support all the known devices.

		pAssign->device = [self indexForDeviceName:pAssign->deviceName];
		if (pAssign->device >= kMaxDevices) {							// beyond device limit?
            [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDeviceController" informativeText:[NSString stringWithFormat:@"Too many data devices in use. Only %d are supported.", kMaxDevices]];
//			NSRunAlertPanel(@"LLDataDeviceController",
//						@"Too many data devices in use. Only %d are supported.", 
//						@"OK", nil, nil, kMaxDevices);
			exit(0);
		}
	}
	
// We now have complete DataAssignments and can create the LLDataAssignments objects 
// and update their settings with values stored in defaults, if any.  All member in 
// the group get the same type name.  If we end up with a device or channel that
// does not exist, revert the assignment to the Null device

	groupArray = [NSMutableArray arrayWithCapacity:0];			// array for group
	for (index = 0, pAssign = assignments; index < count; index++, pAssign++) {
		assign = [[[LLDataAssignment alloc] initWithName:assignments[0].name
					channel:pAssign->channel device:pAssign->device 
					type:dataType groupIndex:index] autorelease];
		[groupArray addObject:assign];							// add to group array
		[self readDefaults:[groupArray objectAtIndex:index] pTiming:&pAssign->timing];

// At this point the LLDataAssigments have a valid device index, but the channel has
// not be checked.  If the channel is not valid, revert this assignment to the Null
// device.  

		device = [dataDevices objectAtIndex:[assign device]];
		if ([assign channel] < 0) {
			[self assignToNullDevice:assign];
		}
		else if ([assign type] == kLLSampleData && [assign channel] >= [device sampleChannels]) {
			[self assignToNullDevice:assign];
		}
		else if ([assign type] == kLLTimestampData && [assign channel] >= [device timestampChannels]) {
			[self assignToNullDevice:assign];
		}

// We now have an assignment with a unique name, and a valid device and channel.  The next step is
// to check for conflicts with existing assignments for devices and channels.  We can do this
// by checking whether the corresponding sampleData or timestampData entry has been initialized.
// Once the assignment is validated, we can finish initializing it.

		if ([assign type] == kLLSampleData) {
			if (sampleData[[assign device]][[assign channel]] != nil) {
				[self assignToNullDevice:assign];
			}
			device = [dataDevices objectAtIndex:[assign device]];	// reload device
			[sampleAssignments addObject:assign];
			sampleData[[assign device]][[assign channel]] = [[NSMutableData alloc] init];
			[device setSamplePeriodMS:assignments[0].timing channel:[assign channel]];
		}
		else {
			if (timestampData[[assign device]][[assign channel]] != nil) {
				[self assignToNullDevice:assign];
			}
			device = [dataDevices objectAtIndex:[assign device]];	// reload device
			[timestampAssignments addObject:assign];
			timestampData[[assign device]][[assign channel]] = [[NSMutableData alloc] init];
			[device setTimestampTicksPerMS:assignments[index].timing channel:[assign channel]];
		}

// Save the current settings

		[self writeDefaults:assign];
	}

// Add the new assignments to the assignment dictionary using the name of the data
// type as a key

	[assignmentDict setObject:groupArray forKey:assignments[0].name];
	[self enableDevicesAndChannels];
	[deviceLock unlock];
}

- (void)assignGroupedSampleData:(DataAssignment *)assignments groupCount:(long)count;
{
	[self assignGroupedData:assignments groupCount:count type:kLLSampleData];
}

- (void)assignSampleData:(DataAssignment)assignment;
{
	[self assignGroupedData:&assignment groupCount:1 type:kLLSampleData];
}

- (void)assignTimestampData:(DataAssignment)assignment;
{
	[self assignGroupedData:&assignment groupCount:1 type:kLLTimestampData];
}

- (void)assignToNullDevice:(LLDataAssignment *)assign;
{
	long channelIndex;
	
	[assign setDevice:0];
	switch ([assign type]) {
	case kLLSampleData:
		for (channelIndex = 0; sampleData[0][channelIndex] != nil; channelIndex++) {};
		break;
	case kLLTimestampData:
		for (channelIndex = 0; timestampData[0][channelIndex] != nil; channelIndex++) {};
		break;
	}
	[assign setChannel:[NSNumber numberWithLong:channelIndex]];
}

- (void)changeDataAssignment:(NSMutableData **)oldDeviceData oldChannel:(long)oldChannel 
				newDeviceData:(NSMutableData **)newDeviceData newChannel:(long)newChannel;
{
	[oldDeviceData[oldChannel] setLength:0];
	newDeviceData[newChannel] = oldDeviceData[oldChannel];
	oldDeviceData[oldChannel] = nil;
}

// Respond when the user changes the menus selecting digital input or output.

- (IBAction)changeDigitalInput:(id)sender;
{
	LLDataDevice *theDevice;
	
	theDevice = [dataDevices objectAtIndex:[digitalInMenu indexOfSelectedItem]];
	[defaults setObject:[theDevice name] forKey:LLDataDeviceDigitalInKey];
}

- (IBAction)changeDigitalOutput:(id)sender;
{
	LLDataDevice *theDevice;
	
	theDevice = [dataDevices objectAtIndex:[digitalOutMenu indexOfSelectedItem]];
	[defaults setObject:[theDevice name] forKey:LLDataDeviceDigitalOutKey];
}

- (void)configureDeviceWithIndex:(long)index {

	[[dataDevices objectAtIndex:index] configure];
}

- (IBAction)configureDataDevice:(id)sender;
{
	LLDataAssignment *assign;
	NSTableView *theTable;
	long selectedRow;
	
	if (![[[self window] firstResponder] isKindOfClass:[NSTableView class]]) {
		return;
	}
	theTable = (NSTableView *)[[self window] firstResponder];
	selectedRow = [theTable selectedRow];
	if (selectedRow < 0) {
		return;
	}
	if ([[self window] firstResponder] == sampleTable) {
		assign = [sampleAssignments objectAtIndex:[theTable selectedRow]];
	}
	else {                                              // [[self window] firstResponder] == timestampTable)
		assign = [timestampAssignments objectAtIndex:[theTable selectedRow]];
	}
	[[dataDevices objectAtIndex:[assign device]] configure];
}

- (void)contingentReadDataFromDevices:(BOOL)onlyIfEnabled;
{
	long deviceIndex, channel;
	NSData **pData;
	LLDataDevice *theDevice;
	
	[deviceLock lock];
	for (deviceIndex = 0; deviceIndex < [dataDevices count]; deviceIndex++) {
		theDevice = [dataDevices objectAtIndex:deviceIndex];
		if (onlyIfEnabled) {
			if (![theDevice deviceEnabled] || ![theDevice dataEnabled]) {
				continue;
			}
		}
		if ((pData = [theDevice sampleData]) != nil) {
			for (channel = 0; channel < [theDevice sampleChannels]; channel++) {
				if (sampleData[deviceIndex][channel] != nil && pData[channel] != nil) {
					[sampleData[deviceIndex][channel] appendData:pData[channel]];
				}
			}
		}
		if ((pData = [theDevice timestampData]) != nil) {
			for (channel = 0; channel < [theDevice timestampChannels]; channel++) {
				if (timestampData[deviceIndex][channel] != nil && pData[channel] != nil) {
					[timestampData[deviceIndex][channel] appendData:pData[channel]];
				}
			}
		}
	}
	lastCollectionTimeS = [LLSystemUtil getTimeS];
	[deviceLock unlock];
}

// Returns all data of that has been assigned to a given type

- (NSData *)dataOfType:(NSString *)typeName;
{
	long index, sample, sampleCount, members;
	short **memberData;
	LLDataAssignment *assign;
	NSArray *assignments;
	NSMutableData *data;
	NSMutableArray *dataArray;

// Check the data type exists
	
	if ((assignments = [assignmentDict objectForKey:typeName]) == nil) {
		return nil;
	}
	
// Make sure that the data has been collected from devices recently

	if ([LLSystemUtil getTimeS] - lastCollectionTimeS > minCollectionIntS) {
		[self contingentReadDataFromDevices:YES];
	}
	
// If this assignment is not grouped data, we can just return the single data entry

	members = [assignments count];
	if (members == 1) {
		[deviceLock lock];
		assign = [assignments objectAtIndex:0];
		switch ([assign type]) {
		case kLLSampleData:
			data = [NSMutableData dataWithData:sampleData[[assign device]][[assign channel]]];
			[sampleData[[assign device]][[assign channel]] setLength:0];
			break;
		case kLLTimestampData:
        default:
			data = [NSMutableData dataWithData:timestampData[[assign device]][[assign channel]]];
			[timestampData[[assign device]][[assign channel]] setLength:0];
			break;
		}
		[deviceLock unlock];
		return ([data length] > 0) ? data : nil;
	}

// If this assignment is grouped, we need to package the data 

	dataArray = [NSMutableArray arrayWithCapacity:members];
	[deviceLock lock];
	for (index = 0, sampleCount = LONG_MAX; index < members; index++) {
		assign = [assignments objectAtIndex:index];
		[dataArray addObject:sampleData[[assign device]][[assign channel]]];
		sampleCount = MIN(sampleCount, 
					[sampleData[[assign device]][[assign channel]] length] / sizeof(short));
	}
	if (sampleCount == 0) {
		[deviceLock unlock];
		return nil;
	}
	memberData = (short **)malloc(sizeof(Ptr) * members);
	for (index = 0; index < members; index++) {
		memberData[index] = (short *)[[dataArray objectAtIndex:index] bytes];
	}
	data = [NSMutableData dataWithLength:0];
	for (sample = 0; sample < sampleCount; sample++) {
		for (index = 0; index < members; index++) {
			[data appendBytes:memberData[index]++ length:sizeof(short)];
		}
	}
	for (index = 0; index < members; index++) {
		[[dataArray objectAtIndex:index] replaceBytesInRange:NSMakeRange(0, sampleCount * sizeof(short))
				withBytes:nil length:0];
	}
	free(memberData);
	[deviceLock unlock];
	return ([data length] > 0) ? data : nil;
}

- (void)dealloc;
{
	[deviceLock lock];
	[dataDevices release];
	[sampleAssignments release];
	[timestampAssignments release];
	[assignmentDict release];
	[deviceDict release];
	[defaults release];
	[deviceLock unlock];
	[deviceLock release];
    [super dealloc];
}

- (LLDataDevice *)deviceWithName:(NSString *)name;
{
	LLDataDevice *device;
	NSEnumerator *enumerator = [dataDevices objectEnumerator];

	while ((device = [enumerator nextObject]) != nil) {
		if ([[device name] isEqualToString:name]) {
			return device; 
		}
    }
	return nil;
}

// Respond to requests for digital input or output words.  The device is stored as a string 
// in defaults.  Note that if there is no device with the default name, nil will be returned
// forcing the command to the Null device, which is always placed at index 0.

- (unsigned long)digitalInputBits;
{
	LLDataDevice *inDevice;
	
	inDevice = [deviceDict objectForKey:[defaults stringForKey:LLDataDeviceDigitalInKey]];
	return [inDevice digitalInputBits];
}

- (void)digitalOutputBits:(unsigned long)bits;
{
	LLDataDevice *outDevice;
	
	outDevice = [deviceDict objectForKey:[defaults stringForKey:LLDataDeviceDigitalOutKey]];
	[outDevice digitalOutputBits:bits];
}

- (void)digitalOutputBitsOff:(unsigned long)bits;
{
	LLDataDevice *outDevice;
	
	outDevice = [deviceDict objectForKey:[defaults stringForKey:LLDataDeviceDigitalOutKey]];
	[outDevice digitalOutputBitsOff:bits];
}

- (void)digitalOutputBitsOn:(unsigned long)bits;
{
	LLDataDevice *outDevice;
	
	outDevice = [deviceDict objectForKey:[defaults stringForKey:LLDataDeviceDigitalOutKey]];
	[outDevice digitalOutputBitsOn:bits];
}

// Enable all devices associated with sample or timestamp assignments

- (void)enableDevicesAndChannels;
{	
	long index;
	LLDataAssignment *assign;
	LLDataDevice *dataDevice;
	NSEnumerator *assignmentEnum;
	NSArray *assignments[] = {sampleAssignments, timestampAssignments};
	
	for (index = 0; index < kLLAssignmentTypes; index++) {
		assignmentEnum = [assignments[index] objectEnumerator];
		while (assign = [assignmentEnum nextObject]) {
			dataDevice = [dataDevices objectAtIndex:[assign device]];
			[dataDevice setDeviceEnabled:[NSNumber numberWithBool:YES]];
			if ([assign type] == kLLSampleData) {
				[dataDevice enableSampleChannel:[assign channel]];
			}
			else if ([assign type] == kLLTimestampData) {
				[dataDevice enableTimestampChannel:[assign channel]];
			}
		}
	}
}

- (long)indexForDeviceName:(NSString *)name;
{
	LLDataDevice *device;
	NSEnumerator *enumerator = [dataDevices objectEnumerator];

	while ((device = [enumerator nextObject]) != nil) {
		if ([[device name] isEqualToString:name]) {
			return [device deviceIndex]; 
		}
    }
	return 0L;
}

- (id)init;
{
    if ((self =  [super initWithWindowNibName:@"LLDataDeviceController"]) != nil) {
		[self window];									// force window so we can init its contents
		[self setDefaults:[NSUserDefaults standardUserDefaults]];
		dataDevices = [[NSMutableArray alloc] init];
		sampleAssignments = [[NSMutableArray alloc] init];
		timestampAssignments = [[NSMutableArray alloc] init];
		assignmentDict = [[NSMutableDictionary alloc] init];
		deviceDict = [[NSMutableDictionary alloc] init];
		deviceLock = [[NSLock alloc] init];
		minCollectionIntS = 0.005;
		[digitalOutMenu removeAllItems];
		[digitalInMenu removeAllItems];
		[self addDataDevice:[[[LLNullDataDevice alloc] init] autorelease]];
	}
	return self;
}

// Return the name of the device currently assigned to data of a given type

- (NSString *)nameOfDeviceForDataOfType:(NSString *)typeName;
{
	LLDataAssignment *assign;
	NSArray *assignments;
    
    // Check the data type exists
	
	if ((assignments = [assignmentDict objectForKey:typeName]) == nil) {
		return nil;
	}
	
    // If this assignment is grouped, we don't try to handle this (although we could check whether it's one device).
    
	if ([assignments count] > 1) {
        return nil;
    };
    
    assign = [assignments objectAtIndex:0];
    return [[dataDevices objectAtIndex:[assign device]] name];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
    if (tableView == sampleTable) {	
		return [sampleAssignments count];
    }
	else if (tableView == timestampTable) {
		return [timestampAssignments count];
	}
	else {
        return 0;
    }
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

// Force a read from all enabled or disabled devices.  This is needed to purge the buffers after
// the data devices have been disabled.  For normal reads, we don't want to be spending the time
// to query the disabled devices.

- (void)readDataFromDevices;
{
	[self contingentReadDataFromDevices:NO];
}

// Modify an LLDataAssignment based on values stored in defaults.  The deviceName
// is stored as a string, and is converted to an index before use.  If the name doesn't
// correspond to an existing device, it reverts to the Null device.  Other entries are
// not checked for validity.

- (BOOL)readDefaults:(LLDataAssignment *)assign pTiming:(float *)pTiming;
{
	long deviceIndex, channelIndex;
	NSArray *defaultsArray = nil;
	
	if ([assign type] == kLLSampleData) {
		defaultsArray = [defaults arrayForKey:[NSString stringWithFormat:@"%@%@%ld",
			LLDataAssignmentKey, [assign name], [assign groupIndex]]];
	}
	else if ([assign type] == kLLTimestampData) {
		defaultsArray = [defaults arrayForKey:[NSString stringWithFormat:@"%@%@",
			LLDataAssignmentKey, [assign name]]];
	}
	if (defaultsArray == nil) {
		return NO;
	}
	deviceIndex = [self indexForDeviceName:[defaultsArray objectAtIndex:kLLDeviceName]];
	[assign setDevice:[NSNumber numberWithLong:deviceIndex]];
	channelIndex = [[defaultsArray objectAtIndex:kLLChannelIndex] intValue];
	[assign setChannel:[NSNumber numberWithLong:channelIndex]];
	*pTiming = [[defaultsArray objectAtIndex:kLLRateIndex] floatValue];
	return YES;
}

- (void)removeAllAssignments;
{
	long device, channel;
	
	[deviceLock lock];
	[assignmentDict removeAllObjects];
	[sampleAssignments removeAllObjects];
	[timestampAssignments removeAllObjects];
	[sampleTable noteNumberOfRowsChanged];
	[timestampTable noteNumberOfRowsChanged];

	for (device = 0; device < kMaxDevices; device++) {
		for (channel = 0; channel < kMaxChannels; channel++) {
			if (sampleData[device][channel] != nil) {
				[sampleData[device][channel] release];
				sampleData[device][channel] = nil;
			}
			if (timestampData[device][channel] != nil) {
				[timestampData[device][channel] release];
				timestampData[device][channel] = nil;
			}
		}
	}
	[dataDevices makeObjectsPerformSelector:@selector(setDeviceEnabled:) 
				withObject:[NSNumber numberWithBool:NO]];
	[dataDevices makeObjectsPerformSelector:@selector(disableAllChannels)];
	[deviceLock unlock]; 
}

- (void)setDataEnabled:(NSNumber *)state;
{
	[dataDevices makeObjectsPerformSelector:@selector(setDataEnabled:) withObject:state];
}

- (void)setDefaults:(NSUserDefaults *)newDefaults;
{
	[newDefaults retain];
	[defaults release];
	defaults = newDefaults;
}

- (void)setMinCollectionIntervalS:(long)newIntervalS;
{
	minCollectionIntS = newIntervalS;
}

- (void)startDevice;
{
	[dataDevices makeObjectsPerformSelector:@selector(startDevice)];
}

- (void)stopDevice;
{
	[dataDevices makeObjectsPerformSelector:@selector(stopDevice)];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
	LLDataAssignment *assign;
	NSArray *assignments;

    if (tableView == sampleTable) {
		assignments = sampleAssignments;
	}
	else if (tableView == timestampTable) {
		assignments = timestampAssignments;
	}
	else {
		return nil;
	}
	NSParameterAssert(row >= 0 && row < [assignments count]);
	assign = [assignments objectAtIndex:row];
	if ([[tableColumn identifier] isEqual:@"name"]) {
		return ([assign groupIndex] == 0) ? [assign name] :  @"\"";
	}
	if ([[tableColumn identifier] isEqual:@"device"]) {
		return [NSNumber numberWithInt:[assign device]];
	}
	if ([[tableColumn identifier] isEqual:@"channel"]) {
		return [NSNumber numberWithInt:[assign channel]];
	}
	if ([[tableColumn identifier] isEqual:@"period"]) {
		return [NSNumber numberWithFloat:[[dataDevices objectAtIndex:[assign device]]
				samplePeriodMSForChannel:[assign channel]]];
	}
	if ([[tableColumn identifier] isEqual:@"sampleFrequency"]) {
		return [NSNumber numberWithLong:round(1000.0 / 
				[[dataDevices objectAtIndex:[assign device]] samplePeriodMSForChannel:[assign channel]])];
	}
	if ([[tableColumn identifier] isEqual:@"timestampPeriod"]) {
		return [NSNumber numberWithFloat:[[dataDevices objectAtIndex:[assign device]]
				timestampPeriodMSForChannel:[assign channel]]];
	}
	if ([[tableColumn identifier] isEqual:@"tickFrequency"]) {
		return [NSNumber numberWithLong:round(1000.0 / 
				[[dataDevices objectAtIndex:[assign device]]  timestampPeriodMSForChannel:[assign channel]])];
	}
	return @"";
}

// This method is called when the user has put a new entry in the table.  We need to validate
// all changes and update the LLDataAssignment and associated NSData objects.

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
					forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{
	long j, channel, device, newChannel, newDevice;
    LLDataAssignment *assign;
	LLDataDevice *dataDevice;
	NSArray *assignments, *assignArray;
	
    if (aTableView == sampleTable) {
		assignments = sampleAssignments;
	}
	else if (aTableView == timestampTable) {
		assignments = timestampAssignments;
	}
	else {
		return;
	}
	NSParameterAssert(rowIndex >= 0 && rowIndex < [assignments count]);
	assign = [assignments objectAtIndex:rowIndex];
	device = [assign device];
	channel = [assign channel];
	dataDevice = [dataDevices objectAtIndex:device];

// Change the device

	if ([[aTableColumn identifier] isEqual:@"device"]) {
		newDevice = [anObject intValue];
		if (newDevice < [dataDevices count]) {
			[deviceLock lock];
			if (aTableView == sampleTable && sampleData[newDevice][channel] == nil) {
				[self changeDataAssignment:sampleData[device] oldChannel:channel
						newDeviceData:sampleData[newDevice] newChannel:channel];
				[assign setDevice:anObject];
			}
			else if (aTableView == timestampTable && timestampData[newDevice][channel] == nil) {
				[self changeDataAssignment:timestampData[device] oldChannel:channel
						newDeviceData:timestampData[newDevice] newChannel:channel];
				[assign setDevice:anObject];
			}
			[deviceLock unlock];
		}
	}

// Change the channel

	else if ([[aTableColumn identifier] isEqual:@"channel"]) {
		newChannel = [anObject intValue];
		if (newChannel < [dataDevice sampleChannels]) {
			[deviceLock lock];
			if (aTableView == sampleTable && sampleData[device][newChannel] == nil) {
				[self changeDataAssignment:sampleData[device] oldChannel:channel
						newDeviceData:sampleData[device] newChannel:newChannel];
				[assign setChannel:anObject];
			}
			else if (aTableView == timestampTable && timestampData[device][newChannel] == nil) {
				[self changeDataAssignment:timestampData[device] oldChannel:channel
						newDeviceData:timestampData[device] newChannel:newChannel];
				[assign setChannel:anObject];
			}
			[deviceLock unlock];
		}
	}

// Change the timestamp period

	else if ([[aTableColumn identifier] isEqual:@"timestampPeriod"]) {
		[deviceLock lock];
		[dataDevice setTimestampPeriodMS:[anObject floatValue] channel:channel];
		[timestampData[device][channel] setLength:0];
		[deviceLock unlock];
	}
	else if ([[aTableColumn identifier] isEqual:@"tickFrequency"]) {
		[deviceLock lock];
		[dataDevice setTimestampPeriodMS:(1000.0 / [anObject floatValue]) channel:channel];
		[timestampData[device][channel] setLength:0];
		[deviceLock unlock];
	}

// Change the sample period (for samples). For grouped objects, we change all the member
// of the group to keep them on the same sampling period

	else if ([[aTableColumn identifier] isEqual:@"period"]) {
		[deviceLock lock];
		assignArray = [assignmentDict objectForKey:[assign name]];
		for (j = 0; j < [assignArray count]; j++) {
			assign = [assignArray objectAtIndex:j];
			dataDevice = [dataDevices objectAtIndex:[assign device]];
			[dataDevice setSamplePeriodMS:[anObject floatValue] channel:[assign channel]];
			[sampleData[[assign device]][[assign channel]] setLength:0];
		}
		assign = [assignments objectAtIndex:rowIndex];
		[deviceLock unlock];
	}
	else if ([[aTableColumn identifier] isEqual:@"sampleFrequency"]) {
		[deviceLock lock];
		assignArray = [assignmentDict objectForKey:[assign name]];
		for (j = 0; j < [assignArray count]; j++) {
			assign = [assignArray objectAtIndex:j];
			dataDevice = [dataDevices objectAtIndex:[assign device]];
			[dataDevice setSamplePeriodMS:(1000.0 / [anObject floatValue]) channel:[assign channel]];
			[sampleData[[assign device]][[assign channel]] setLength:0];
		}
		assign = [assignments objectAtIndex:rowIndex];
		[deviceLock unlock];
	}
	[self writeDefaults:assign];
	[aTableView reloadData];
}

- (void)writeDefaults:(LLDataAssignment *)assign;
{
	float timing;
	NSString *key;
	long channel = [assign channel];
	LLDataDevice *dataDevice = [dataDevices objectAtIndex:[assign device]];

	if ([assign type] == kLLSampleData) {
		timing = [dataDevice samplePeriodMSForChannel:channel];
		key = [NSString stringWithFormat:@"%@%@%ld", LLDataAssignmentKey, [assign name], 
				[assign groupIndex]];
	}
	else if ([assign type] == kLLTimestampData) {
		timing = [dataDevice timestampPeriodMSForChannel:channel];
		key = [NSString stringWithFormat:@"%@%@", LLDataAssignmentKey, [assign name]];
	}
	else {
		return;
	}
	[defaults setObject:[NSArray arrayWithObjects:[dataDevice name], 
			[NSNumber numberWithLong:channel], [NSNumber numberWithFloat:timing], nil]
			forKey:key];
}

@end
