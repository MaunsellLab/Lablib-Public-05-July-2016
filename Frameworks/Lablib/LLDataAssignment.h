//
//  LLDataAssignment.h
//  Lablib
//
//  Created by John Maunsell on 12/22/05.
//  Copyright 2005. All rights reserved.
//

enum {kLLSampleData, kLLTimestampData, kLLAssignmentTypes};

@interface LLDataAssignment : NSObject {

	long channel;
	long device;
	NSString *name;
	long type;
	long groupIndex;
}

- (long)channel;
- (long)device;
- (long)groupIndex;
- (id)initWithName:(NSString *)theName channel:(long)theChannel device:(long)theDevice 
			type:(long)theType groupIndex:(long)index;
- (NSString *)name;
- (void)setChannel:(NSNumber *)newChannel;
- (void)setDevice:(NSNumber *)newDevice;
- (long)type;

@end
