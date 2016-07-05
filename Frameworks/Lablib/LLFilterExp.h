//
//  LLFilterExp.h
//  Lablib
//
//  Created by John Maunsell on 10/21/08.
//  Copyright 2008 JHRM. All rights reserved.
//

@interface LLFilterExp : NSObject {
	
	long	dataBytes;
	double	filterValue;
	double	stepWeight;

}

- (NSData *)filteredValues:(NSData *)inData;
- (void)reset;
- (void)setDataBytes:(long)newDataBytes;
- (void)setStepWeight:(double)newWeight;
- (double)stepWeight;

@end
