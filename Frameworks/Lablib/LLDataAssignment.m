//
//  LLDataAssignment.m
//  Lablib
//
//  Created by John Maunsell on 12/22/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDataAssignment.h"

@implementation LLDataAssignment

- (long)channel;
{
	return channel;
}

- (void)dealloc;
{
	[name release];
	[super dealloc];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@: name %@; device %ld; channel %ld; type %ld; groupIndex %ld", 
		[self class], name, device, channel, type, groupIndex];
}

- (long)device;
{
	return device;
}

- (long)groupIndex;
{
	return groupIndex;
}

- (id)initWithName:(NSString *)theName channel:(long)theChannel device:(long)theDevice 
			type:(long)theType groupIndex:(long)index;
{
	if (self = [super init]) {
		[theName retain];
		name = theName;
		device = theDevice;
		channel = theChannel;
		type = theType;
		groupIndex = index;
	}
	return self;
}

- (NSString *)name;
{
	return name;
}

- (void)setChannel:(NSNumber *)newChannel;
{
	channel = [newChannel intValue];
}

- (void)setDevice:(NSNumber *)newDevice;
{
	device = [newDevice intValue];
}

- (long)type;
{
	return type;
}

@end
