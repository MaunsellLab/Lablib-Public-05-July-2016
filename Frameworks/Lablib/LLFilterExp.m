//
//  LLFilterExp.m
//  Lablib
//
//  Created by John Maunsell on 10/21/08.
//  Copyright 2008 JHRM. All rights reserved.
//

#import "LLFilterExp.h"

#define kDefaultWeight		0.1
#define kDefaultDataBytes	2

@implementation LLFilterExp

- (NSData *)filteredValues:(NSData *)inData;
{
	long index;
	char *inCharPtr, *outCharPtr;
	short *inShortPtr, *outShortPtr;
	long *inLongPtr, *outLongPtr;
	NSMutableData *outData = [NSMutableData dataWithLength:[inData length]];
	
	
	switch (dataBytes) {
		case 1:
			inCharPtr = (char *)[inData bytes];
			outCharPtr = (char *)[outData mutableBytes];
			break;
		case 2:
			inShortPtr = (short *)[inData bytes];
			outShortPtr = (short *)[outData mutableBytes];
			break;
		case 4:
			inLongPtr = (long *)[inData bytes];
			outLongPtr = (long *)[outData mutableBytes];
			break;
		default:
			break;
	}
	for (index = 0; index < [inData length]; index += dataBytes) {
		switch (dataBytes) {
			case 1:
				filterValue = filterValue * (1.0 - stepWeight) + stepWeight * *inCharPtr++;
				*outCharPtr++ = (char)filterValue;
				break;
			case 2:
				filterValue = filterValue * (1.0 - stepWeight) + stepWeight * *inShortPtr++;
				*outShortPtr++ = (short)filterValue;
				break;
			case 4:
				filterValue = filterValue * (1.0 - stepWeight) + stepWeight * *inLongPtr++;
				*outLongPtr++ = (long)filterValue;
				break;
			default:
				break;
		}
	}
	return outData;
}

- (id)init;
{
	if ((self = [super init])) {
		stepWeight = kDefaultWeight;
		dataBytes = kDefaultDataBytes;
		[self reset];
	}
	return self;
}

- (void)reset;
{
	filterValue = 0.0;
}

- (void)setDataBytes:(long)newDataBytes;
{
	switch (newDataBytes) {
		case 1:
		case 2:
		case 4:
			dataBytes = newDataBytes;
			break;
		default:
			break;
	}
}

- (void)setStepWeight:(double)newWeight;
{
	stepWeight = newWeight;
}

- (double)stepWeight;
{
	return stepWeight;
}

@end
