//
//  LLDataUtil.m
//  Lablib
//
//  Created by John Maunsell on 2/9/06.
//  Copyright 2006. All rights reserved.
//

#import "LLDataUtil.h"


@implementation LLDataUtil

// Pair shorts in two NSMutableData object, return them as NSPoints, and clear them out of the NSMutableData objects

+ (NSArray *)pairXSamples:(NSMutableData *)xSamples withYSamples:(NSMutableData *)ySamples;
{
	short *pX, *pY;
	long xLengthBytes, yLengthBytes, pairedBytes, sample, numPairs;
	NSMutableArray *pairs;
	
	xLengthBytes = [xSamples length];
	yLengthBytes = [ySamples length];
	pairedBytes =  MIN(xLengthBytes, yLengthBytes);
	if (pairedBytes == 0) {
		return nil;
	}
	numPairs = pairedBytes / sizeof(short);
	pairs = [NSMutableArray arrayWithCapacity:numPairs];
	pX = (short *)[xSamples bytes];
	pY = (short *)[ySamples bytes];
	for (sample = 0; sample < numPairs; sample++) {
		[pairs addObject:[NSValue valueWithPoint:NSMakePoint(*pX++, *pY++)]];
	}
	if (xLengthBytes == pairedBytes) {
		[xSamples setLength:0];
	}
	else {
		[xSamples replaceBytesInRange:NSMakeRange(0, xLengthBytes)
					withBytes:pX length:xLengthBytes - pairedBytes];
	}
	if (yLengthBytes == pairedBytes) {
		[ySamples setLength:0];
	}
	else {
		[ySamples replaceBytesInRange:NSMakeRange(0, yLengthBytes)
					withBytes:pY length:yLengthBytes - pairedBytes];
	}
	return(pairs);
}

@end
