//
//  LLDataEventDef.m
//  Lablib
//
//  Created by John Maunsell on 3/11/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDataEventDef.h"
#import "LLSystemUtil.h"

#define		kStructDataType		-1

enum {kNoDataType, kCharType, kUnsignedCharType, kBooleanType, kShortType, kUnsignedShortType,
			kLongType, kUnsignedLongType, kFloatType, kDoubleType, kStringType, kCGFloatType};
			
static NSString *LLDataTypeStrings[] = {@"no data", @"char", @"unsigned char", @"boolean", 
							@"short", @"unsigned short", @"long", @"unsigned long", 
							@"float", @"double", @"string", @"CGFloat"};
							
@implementation LLDataEventDef

- (long)code;
{	
	return code;
}

// Count the number of tags that are defined in a struct definition

- (unsigned long)countStructTags:(LLDataDef *)pDef;
{
	unsigned long count = 0;
	
	for (pDef = pDef->contents; pDef->typeName != nil; pDef++) {
		count++;
	}
	return count;
}

- (long)dataBytes;
{
	return dataBytes;
}

// Return an NSData object that contains the data definitions for this event in a format
// that is appropriate for the header of a data file. For each entry in the data field
// this includes a Pascal string with the data type, a Pascal string with the name of the
// variable, a long with the number of elements (>1 for arrays), a long with the byte offset
// of the field within its struct (if there is one, zero otherwise), and a long with the 
// number of bytes consumed by the field.  This is redundant for most entries, but is needed
// for structs, so that the number of subsequent fields belonging to the struct can be
// determined

- (NSData *)dataDefinition;
{
	unsigned char stringLength;
	LLDataDef dataDef;
	NSValue *value;
	NSMutableData *data;
	NSEnumerator *enumerator;
	
	if (dataDefs == nil) {						// no definitions for this event
		return nil;
	}
	data = [[[NSMutableData alloc] init] autorelease];
	enumerator = [dataDefs objectEnumerator];
	while (value = [enumerator nextObject]) {
        [value getValue:&dataDef];
		stringLength = [dataDef.typeName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];								// write the typeName
		[data appendBytes:&stringLength length:sizeof(stringLength)];		
		[data appendBytes:[dataDef.typeName cStringUsingEncoding:NSUTF8StringEncoding] length:stringLength];
		stringLength = [dataDef.dataName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];								// write the dataName
		[data appendBytes:&stringLength length:sizeof(stringLength)];		
		[data appendBytes:[dataDef.dataName cStringUsingEncoding:NSUTF8StringEncoding] length:stringLength];
		[data appendBytes:&dataDef.offsetBytes length:sizeof(dataDef.offsetBytes)];		// offset in structure		
		[data appendBytes:&dataDef.elements length:sizeof(dataDef.elements)];			// num elements		
		[data appendBytes:&dataDef.elementBytes length:sizeof(dataDef.elementBytes)];	// num bytes		
		[data appendBytes:&dataDef.tags length:sizeof(dataDef.tags)];					// tags (in struct)		
	}
	return data;
}

- (void)dealloc;
{
	NSEnumerator *enumerator;
	NSValue *value;
	LLDataDef dataDef;
	
	enumerator = [dataDefs objectEnumerator];
	while (value = [enumerator nextObject]) {
        [value getValue:&dataDef];
		[dataDef.typeName release];
		[dataDef.dataName release];
    }
	[dataDefs release];

	[name release];
	[super dealloc];
}

- (long)elementBytes;
{
	return elementBytes;
}

// Return the number of bytes per element for a simple data type (short, float).  This 
// is not the total length of a string or array.  The return value has to be multiplied
// by the length of the string or array to get the total.

- (long)entryBytes:(LLDataDef *)pDef;
{
	long index;
    // The number of bytes devoted to a data type can differ depending on whether it is standing
    // alone, or embedded in a structure, where there is padding applied.  This seems to affect
    // only the Boolean type, which is a single byte by itself, but two bytes in a structure
    
#if defined(__LP64__) && __LP64__
    static unsigned short LLDataTypeBytes[] = {0, 1, 1, 1, 2, 2, 4, 4, 4, 8, 1, 8};
#else
    static unsigned short LLDataTypeBytes[] = {0, 1, 1, 1, 2, 2, 4, 4, 4, 8, 1, 4};
#endif

// An index of -1 is a structure, for which we return -1

	index = [self simpleTypeIndex:pDef];
	if (index >= 0) {
		return LLDataTypeBytes[index];
	}
	else {
		if (pDef->elementBytes == 0) {
            [LLSystemUtil runAlertPanelWithMessageText:@"LLDataEventDef" informativeText:[NSString stringWithFormat:
                        @"Struct %@ in event definition for %@ did not declare number of bytes",name, pDef->typeName]];
//             NSRunAlertPanel(@"LLDataEventDef", @"Struct %@ in event definition for %@ did not declare number of bytes",
//                             @"OK", nil, nil, name, pDef->typeName);
			exit(0);
		}
		return pDef->elementBytes;
	}
}

// Parse the data for one instance of the event, returning an array of strings
// that has one entry for each element in the data field of the instance. 
// The strings are Matlab commands for creating variables related to the event.
// The prefix passed in is a string that should prefix every line.  It is used 
// to allow different instances of the same event type to be distinguished, and 
// is typically something like @"trial(3)."  The suffix passed in is a string
// that is a suffix for the data name on each line.  It makes it possible to 
// distinguish multiple occurences of one type of event within a given trial,
// as in "trial(3).event(4) = ..."

- (NSArray *)eventDataAsStrings:(DataEvent *)pEvent prefix:(NSString *)prefix
								suffix:(NSString *)suffix;
{
	char nullChar = 0;
	NSMutableData *cStringData;
	LLDataDef def;

// Can't proceed without valid event instance and valid data definitions
	
	if (pEvent == nil || dataDefs == nil) {
		return nil;
	}
	prefix = (prefix == nil) ? @"" : prefix;				// need a valid NSString for prefix
	suffix = (suffix == nil) ? @"" : suffix;				// need a valid NSString for suffix
	[[dataDefs objectAtIndex:0] getValue:&def];				// get top level definition

// We assume that events of type "no data" are being used as time stamps.  If this is an 
// event with no data, we set its value to the time since the start of the trial

	if ([def.typeName isEqualToString:@"no data"]) {
		return [NSArray arrayWithObject:[NSString stringWithFormat:@"%@%@%@ = %lu",
				prefix, def.dataName, suffix, pEvent->trialTime]];
	}
	
// We need valid data to proceed

	if (pEvent->data == nil) {
		return nil;
	}

// Strings are also given special processing, because Matlab needs them enclosed with
// single quotes. Strings only occur at the top level of the data (here). 

	if ([def.typeName isEqualToString:@"string"]) {
		prefix = [prefix stringByAppendingString:
						[NSString stringWithFormat:@"%@%@", def.dataName, suffix]];
		cStringData = [NSMutableData dataWithData:pEvent->data];	// get the chars
		[cStringData appendBytes:&nullChar length:sizeof(char)];	// null terminate
		return [NSArray arrayWithObject:[NSString stringWithFormat:
				@"%@ = \'%s\'", prefix,[cStringData bytes]]];
	}

// Parse the event

	defIndex = 0;
	return [self eventEntryAsStrings:(Ptr)[pEvent->data bytes] length:[pEvent->data length]
							prefix:prefix suffix:suffix];
}

/*
Return a string that is a space-separated list of the elements in the data.  This is used
by LLDataFileReader to collect sets of bundled data (e.g., eye samples, spikes) into a string
buffer that is later used to create one command line to make Matlab create an array of data.
Currently only simple data types are supported.  The string has no prefix or suffix, it is just
the raw entries, separated by commas
*/

- (NSString *)eventDataElementsAsString:(DataEvent *)pEvent;
{
	long index, dataType, items;
	LLDataDef def;
	NSMutableString *theString;

// Can't proceed without valid event instance and valid data definitions
	
	if (pEvent == nil || pEvent->data == nil || dataDefs == nil) {
		return nil;
	}
	[[dataDefs objectAtIndex:0] getValue:&def];				// get top level definition

// We only return these strings for simple data types, and not strings either.

	dataType = [self simpleTypeIndex:&def];
	if (dataType == kNoDataType || dataType == kStringType || dataType == kStructDataType) {
		return nil;
	}
	if (def.elements == 1) {							// single, simple entry
		theString = [NSMutableString stringWithFormat:@"%@,", [self stringForType:dataType 
					buffer:((Ptr) [pEvent->data bytes] + def.offsetBytes) index:0]];
	}
	else {												// array of simple entries
		items = (def.elements == -1) ? ([pEvent->data length] / def.elementBytes) : def.elements;
		theString = [NSMutableString stringWithFormat:@""];
		for (index = 0; index < items; index++) {
			[theString appendFormat:@"%@,", [self stringForType:dataType 
					buffer:((Ptr)[pEvent->data bytes] + def.offsetBytes) index:index]];
		}
	}
	return theString;
}

/*
Return an array of strings describing all the entries for one item in the data event.
The items return consist of one pass through the contents of the event definition
This might be a single, simple item (short, long, float), a string defining an
array of simple items, or (potentially) nested structures.  This method calls
itself recursively for embedded structs or arrays of structs.
We access the LLEventDef array using defIndex.  We have to use this approach, because
there is no way of knowing in advance how many definitions are needed for a structure -
it can be many more than the number of structure tags if some of the tags are themselves
structures.  defIndex is incremented every time a definition is read, and if a struct
must be parsed repeatedly (struct array), it can be reset for each struct.
*/


- (NSArray *)eventEntryAsStrings:(Ptr)dataPtr length:(long)length 
						prefix:(NSString *)prefix suffix:(NSString *)suffix;
{
	long index, items, tag, dataType, previousPrefixIndex, previousDefIndex;
	Ptr structPtr;
	NSMutableArray *strings;
	NSMutableString *theString;
	LLDataDef def;

	strings = [[[NSMutableArray alloc] init] autorelease];
	[[dataDefs objectAtIndex:defIndex] getValue:&def];		// get definition for this item
	dataType = [self simpleTypeIndex:&def];					// get index for type of item
	if (dataType != kStructDataType) {						// is this a simple type?
		if (def.elements == 1) {							// single, simple entry
			theString = [NSMutableString stringWithFormat:@"%@%@%@ =%@", prefix, def.dataName,
						suffix,	[self stringForType:dataType 
						buffer:(dataPtr + def.offsetBytes) index:0]];
		}
		else {												// array of simple entries
			items = (def.elements == -1) ? (length / def.elementBytes) : def.elements;
			theString = [NSMutableString stringWithFormat:@"%@%@ = [", 
							prefix, def.dataName];
			for (index = 0; index < items; index++) {
				[theString appendString:[self stringForType:dataType 
						buffer:(dataPtr + def.offsetBytes) index:index]];
				if (((index % 2000) == 0) && (index > 0)) {
					[theString appendString:[NSString stringWithFormat:@"];\n%@%@ = [%@%@ ",
						prefix, def.dataName, prefix, def.dataName]];
					}
				if (((index % 25) == 0) && (index > 0)) {
					[theString appendString:[NSString stringWithFormat:@" ...\n"]];
				}
			}
			[theString appendString:@"]"];
		}
		[strings addObject:theString];
	}
	else {													// struct
		structPtr = dataPtr + def.offsetBytes;
		if (def.elements == 1) {							// single struct entry
			prefix = [prefix stringByAppendingString:		// add struct name to prefix
							[NSString stringWithFormat:@"%@%@.", def.dataName, suffix]];
			for (tag = 0; tag < def.tags; tag++) {			// get each struct tag
				defIndex++;
				[strings addObjectsFromArray:
						[self eventEntryAsStrings:structPtr
						length:length prefix:prefix suffix:@""]];
			}
		}
		else {												// array of structs
			prefix = [prefix stringByAppendingString:
							[NSString stringWithFormat:@"%@", def.dataName]];
			previousPrefixIndex = [prefix length];			// save for later restore of prefix
			previousDefIndex = defIndex;
			items = (def.elements == -1) ? (length / def.elementBytes) : def.elements;
			for (index = 0; index < items; index++) {		// for each struct instance in array
				prefix = [prefix stringByAppendingString:	// upate the prefix
							[NSString stringWithFormat:@"(%ld).", index + 1]];
				defIndex = previousDefIndex;
				for (tag = 0; tag < def.tags; tag++) {		// get each struct tag
					defIndex++;								// advance to next definition
					[strings addObjectsFromArray:			// append one tag's strings
						[self eventEntryAsStrings:(structPtr + index * def.elementBytes) 
						length:length prefix:prefix suffix:@""]];
				}
				prefix = [prefix substringToIndex:previousPrefixIndex]; // restore prefix
			}
		}
	}
	return strings;
}

// Perform initialization without data definitions

- (id)initWithCode:(long)initCode name:(NSString *)initName dataBytes:(long)initBytes;
{
	if ((self = [super init]) != nil) {
		code = initCode;
		[initName retain];
		name = initName;
		dataBytes = initBytes;
		dataDefs = [[NSMutableArray alloc] init];
	}
	return self;
}

// Perform initialization with data defintions

- (id)initWithCode:(long)initCode name:(NSString *)initName elementBytes:(long)eleBytes
			dataDefinition:(LLDataDef *)pDataDef;
{
	if (pDataDef == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:@"LLDataEventDef" informativeText:[NSString stringWithFormat:
                      @"Attempting to define event \"%@\" without defining its contents", name]];
//		NSRunAlertPanel([self className],
//					@"Attempting to define event \"%@\" without defining its contents", 
//					@"OK", nil, nil, name);
		exit(0);
	}
	if ((self = [super init]) != nil) {
		code = initCode;						// unique code for this data event
		[initName retain];
		name = initName;						// name of event

// Get the number of bytes in each data element, and the total number of data bytes per event.
// Some special assumptions are made about the "string" type.

		isStringData = [pDataDef->typeName isEqualTo:@"string"];
		if (isStringData) {
			elementBytes = pDataDef->elementBytes = sizeof(char);
			dataBytes = pDataDef->elements = -1;
		}
		else {
			elementBytes = eleBytes;				// declared bytes per element
			pDataDef->elements = (pDataDef->elements == 0) ? 1 : pDataDef->elements;
			dataBytes = (pDataDef->elements == -1) ? -1 : pDataDef->elements * elementBytes;
		}
		
// Parse the definition, tallying the number of data bytes
		
		dataDefs = [[NSMutableArray alloc] init];
		nestLevel = offsetBytes = tags = 0;
		if (![self parseDefinition:pDataDef]) {
			NSLog(@"LLDataEventDef: couldn't parseDefinitions");
			exit(0);
		}
	}
	return self;
}

- (BOOL)isStringData;
{
	return isStringData;
}

- (NSString *)name;
{
	return name;
}

// Adjust the offset for an entry in a struct to allow for padding that occurs to
// align the fields.

- (unsigned long)padBytes:(unsigned long)sizeBytes offset:(unsigned long)theOffset;
{
	long byteOffset;
	
	byteOffset = (theOffset % MIN(sizeBytes, 4));
	if (byteOffset > 0) {
		theOffset += MIN(sizeBytes, 4) - byteOffset;
	}
	return theOffset;
}

// Parse the definitions for a data field entry.  If the definition is for a simple data type 
// (char, short, etc) the treatment is simple.  If it is a struct, then this method calls itself 
// recursively to pull out all the nested definitions (e.g., stucts within structs).  It also 
// does error checking on the definitions. It compiles a list of entries into dataDefs.
// This method unpacks the definitions of structs so that they become one LLDataDef that is
// a struct, followed by a list of LLDataDefs that are the contents of the struct.  There 
// is an entry in LLDataDef (tag) that tell how many of the following LLDataDefs belong to the
// struct. 

- (BOOL)parseDefinition:(LLDataDef *)pDef;
{
	long bytes, tempOffsetBytes;

	if (pDef->typeName == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                      @"Error with description of data event %@: Entry with no type name", name]];
//		NSRunAlertPanel([self className],
//				@"Error with description of data event %@: Entry with no type name", 
//				@"OK", nil, nil, name);
		exit(0);
	}
	[pDef->typeName retain];

// Users can define events as "string" without filling in the fields.  We fill them here

	if ([pDef->typeName isEqualTo:@"string"]) {
		pDef->elements = -1;
	}
	
// Check the number of elements. The number of elements can be -1 only for the top level 
// definition (nestLevel == 0), or for the final entry in a struct.  For the latter, the
// offset must match the arrayOffsetBytes, which would have been initialized in parsing
// the top level definition. Users may leave the elements uninitialized (nil), because it 
// simplifies initialization, but we set it to the correct value here.

	if (pDef->elements == -1) {
		if (nestLevel > 0 && (pDef->offsetBytes != arrayOffsetBytes)) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                           @"Data event %@: Invalid data defined as having -1 elements", name]];
//			NSRunAlertPanel([self className],
//					@"Data event %@: Invalid data defined as having -1 elements", 
//					@"OK", nil, nil, name);
			exit(0);
		}
	}
	else {
		pDef->elements = MAX(pDef->elements, 1);
	}
	
// It is valid to give a NULL name, in which case the event name is taken, but
// it cannot be NULL for nested structs (because there might be more than one NULL).

	if (pDef->dataName == nil) {
		if (nestLevel > 0) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                    @"Error in description of data event %@: Unnamed data of type %@", name, pDef->typeName]];
//			NSRunAlertPanel([self className],
//					@"Error in description of data event %@: Unnamed data of type %@", 
//					@"OK", nil, nil, name, pDef->typeName);
			exit(0);
		}
		pDef->dataName = name;							// give data the name of event
	}
	[pDef->dataName retain];

// If this is the base level for the event, the offset should generally be zero.  The  only
// exception is for indeterminate arrays with headers.  In that case the offset at the base
// level give the start of the indeterminate array.

	if (nestLevel == 0 && pDef->offsetBytes > 0) {
		if (![pDef->typeName isEqualToString:@"struct"]) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                 @"Error in description of data event %@: offsetBytes != 0 for entry \"%@\"", name, pDef->typeName]];
//			NSRunAlertPanel([self className],
//				@"Error in description of data event %@: offsetBytes != 0 for entry \"%@\"", 
//				@"OK", nil, nil, name, pDef->typeName);
			exit(0);
		}
		else {
			arrayOffsetBytes = pDef->offsetBytes;
		}
	}

// If the offsetBytes given are less than the number of bytes so far, something is wrong

	if (pDef->offsetBytes < offsetBytes) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
               @"Error in description of data event %@: offsetBytes (%ld) looks too small for entry \"%@\"",
               name, pDef->offsetBytes, pDef->dataName]];
//		NSRunAlertPanel([self className],
//				@"Error in description of data event %@: offsetBytes (%ld) looks too small for entry \"%@\"", 
//				@"OK", nil, nil, name, pDef->offsetBytes, pDef->dataName);
		exit(0);
	}

// Get the number of bytes in this element.  For simple types, it is the size of the type.
// For structs, it is the total size of the struct.  The value is not affected by whether
// the entry is an array: arrays are indicated by the "elements" entry.

	bytes = pDef->elementBytes = [self entryBytes:pDef];
	
// If the data has a simple type (array or not), then we only need to register the information
// in dataDef and we are done.

	if ([self simpleTypeIndex:pDef] >= 0) {				// it's a simple data type
		[dataDefs addObject:[NSValue valueWithBytes:pDef objCType:@encode(LLDataDef)]];
//		NSLog(@"   \"%@\" \"%@\" in \"%@\" (offset %d, %d elem, %d bytes total)", 
//			pDef->typeName, pDef->dataName, name, pDef->offsetBytes, pDef->elements, bytes);
		offsetBytes = pDef->offsetBytes + bytes * pDef->elements;
		return YES;
	}
	
// It's not a simple type it's a struct and it must contain a definition

	if (![pDef->typeName isEqualToString:@"struct"]) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                @"Error with description of data event %@: Unrecognized data type \"%@\"", name, pDef->typeName]];
//		NSRunAlertPanel([self className],
//				@"Error with description of data event %@: Unrecognized data type \"%@\"", 
//				@"OK", nil, nil, name, pDef->typeName);
		exit(0);
	}
	if (pDef->contents == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
               @"Error with description of data event %@: struct \"%@\" has no contents definition",
               pDef->typeName, pDef->dataName]];
//		NSRunAlertPanel([self className],
//				@"Error with description of data event %@: struct \"%@\" has no contents definition", 
//				@"OK", nil, nil, pDef->typeName, pDef->dataName);
		exit(0);
	}

// Pass through the struct description adding up the bytes.  This is complicated by the fact that there
// is padding in most structures.  I have not tried to do the GCC check on what type of element alignment
// is used, but assumed that it is the normal type, in which each entry is aligned to a field of its
// own size or 4 bytes, whichever is less, and that the whole struct is padded to a whole multiple of its
// largest element (up to 8).

	pDef->tags = [self countStructTags:pDef];
//	NSLog(@"   Parsing  \"struct\" named \"%@\" in event \"%@\" (offset %lu, %lu tags, %lu bytes)",
//				pDef->dataName, name, pDef->offsetBytes, pDef->tags, pDef->elementBytes);
	[dataDefs addObject:[NSValue valueWithBytes:pDef objCType:@encode(LLDataDef)]];
	tempOffsetBytes = pDef->offsetBytes + pDef->elementBytes * pDef->elements;
	offsetBytes = 0;
	nestLevel++;
	for (pDef = pDef->contents; pDef->typeName != nil; pDef++) {
		if (![self parseDefinition:pDef]) {
			return NO;
		}
	}
	nestLevel--;
	offsetBytes = tempOffsetBytes;
	return YES;
}

// Read the data definitions for the data event.  This is the method used to create
// the dataDefs entries from entries in a binary data file. 

- (void)readDefinitionsFromFile:(id<LLDataReader>)dataFileReader;
{
	long bytes, tag;
	LLDataDef dataDef;

	dataDef.contents = nil;								// not used when reading from file
	dataDef.typeName = [dataFileReader dataString];		// get the type name of the data entry
	[dataDef.typeName retain];
	isStringData = [dataDef.typeName isEqualTo:@"string"];
	dataDef.dataName = [dataFileReader dataString];		// get the data name of the data entry
	[dataDef.dataName retain];
	[dataFileReader dataBytes:(Ptr)&dataDef.offsetBytes length:sizeof(dataDef.offsetBytes)];
	[dataFileReader dataBytes:(Ptr)&dataDef.elements length:sizeof(dataDef.elements)];
	[dataFileReader dataBytes:(Ptr)&dataDef.elementBytes length:sizeof(dataDef.elementBytes)];
	[dataFileReader dataBytes:(Ptr)&dataDef.tags length:sizeof(dataDef.tags)];

	bytes = [self entryBytes:&dataDef];					 // check the number of bytes is correct
	NSAssert(dataDef.elementBytes == bytes, @"Inconsistent number of bytes store in event data description");
	[dataDefs addObject:[NSValue valueWithBytes:&dataDef objCType:@encode(LLDataDef)]];
	
// If this is a simple data type, we are done, if it is a struct, proceed with the (potentially nested) 
// definitions of the structure

	if ([dataDef.typeName isEqualToString:@"struct"]) {
		for (tag = 0; tag < dataDef.tags; tag++) {
			[self readDefinitionsFromFile:dataFileReader];
		}
	}
}

// Return the an index for a simple data type or simple data type array.

- (long)simpleTypeIndex:(LLDataDef *)pDef;
{
	long type;

	for (type = 0; type < sizeof(LLDataTypeStrings) / sizeof(Ptr); type++) {
		if ([pDef->typeName isEqualToString:LLDataTypeStrings[type]]) {
			return type;
		}
	}
	if (![pDef->typeName isEqualToString:@"struct"]) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
               @"Unrecognized type in data definition: \"%@\"",pDef->typeName]];
//		NSRunAlertPanel(@"LLDataEventDef",  @"Unrecognized type in data definition: \"%@\"",
//				@"OK", nil, nil, pDef->typeName);
		exit(0);
	}
	return -1;				// not a simple data type (e.g., a struct)
}

// Return a string that contains only a simple value as a string with a space
// for padding (e.g., "10 ").  The data for the value are taken from the buffer
// at dataPtr, offset by the size of the element and the index.

- (NSString *)stringForType:(long)dataType buffer:(Ptr)dPtr index:(long)index;
{
	NSString *theString;
	
	switch (dataType) { 
	case kNoDataType:
		theString = [NSString stringWithFormat:@" []"];
		break;
	case kCharType:
		theString = [NSString stringWithFormat:@" %hhi", ((char *)dPtr)[index]];
		break;
	case kUnsignedCharType:
		theString = [NSString stringWithFormat:@" %hhu", ((unsigned char *)dPtr)[index]];
		break;
	case kBooleanType:
		theString = [NSString stringWithFormat:@" %hhi", ((BOOL *)dPtr)[index]];
		break;
	case kShortType:
		theString = [NSString stringWithFormat:@" %hi", ((short *)dPtr)[index]];
		break;
	case kUnsignedShortType:
		theString = [NSString stringWithFormat:@" %hu", ((unsigned short *)dPtr)[index]];
		break;
	case kLongType:
		theString = [NSString stringWithFormat:@" %ld", ((long *)dPtr)[index]];
		break;
	case kUnsignedLongType:
		theString = [NSString stringWithFormat:@" %lu", ((unsigned long *)dPtr)[index]];
		break;
	case kFloatType:
		theString = [NSString stringWithFormat:@" %f", ((float *)dPtr)[index]];
		break;
	case kDoubleType:
		theString = [NSString stringWithFormat:@" %f", ((double *)dPtr)[index]];
		break;
	case kStringType:
		theString = [NSString stringWithFormat:@" '%s'", &((char *)dPtr)[index]];
		break;
    case kCGFloatType:
#if defined(__LP64__) && __LP64__
        theString = [NSString stringWithFormat:@" %f", ((double *)dPtr)[index]];
#else
        theString = [NSString stringWithFormat:@" %f", ((float *)dPtr)[index]];
#endif
        break;
	default:
		theString = nil;
		break;
	}
	return theString;
}	

@end
