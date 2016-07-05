/*
 *  LLDataEvents.h
 *  Lablib
 *
 *  Created by John Maunsell on 12/25/05.
 *  Copyright 2005. All rights reserved.
 *
 */

typedef struct {
    NSString		*name;
    NSData			*data;
    unsigned long	time;						// time (of day) the event was posted
	unsigned long	trialTime;					// time of the event since trialStart
	unsigned long	code;						// code for this type of event in data file
	unsigned long	fileIndex;					// byte offset in file
} DataEvent;

typedef struct LLDataDef {
	NSString		*typeName;					// name of the type of data (long, short...)
	NSString		*dataName;					// name of the data entry
	long			elements;					// number of elements (for arrays)
	unsigned long	offsetBytes;				// bytes from the start of data
	unsigned long	elementBytes;				// number of bytes in an element
	struct LLDataDef *contents;					// additional contents (for structs)
	unsigned long	tags;						// number of tags (in a structure only)
} LLDataDef;
    
// Old event definition that includes only the name and dataBytes.

typedef struct {	
	NSString *name;								// string with name of event
	long dataBytes;								// Number of data bytes
} EventDef;

// New event definition, which includes the type(s) and name(s) of the data.
// For elementBytes, an element is all the data for non-arrays, or the size of one entry 
// in an array or indeterminate array

typedef struct {	
	NSString *name;								// string with name of event
	long elementBytes;							// bytes in each element of data
	LLDataDef definition;						// definition of the data content
} EventDefinition;

// Event descriptor, used internally to describe events

typedef struct {	
	long code;									// string with name of event
    NSString *name;								// string with name of event
	long dataBytes;								// Number of data bytes
} EventDesc;
