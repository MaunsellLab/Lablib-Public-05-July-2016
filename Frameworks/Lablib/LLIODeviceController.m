//
//  LLIODeviceController.m
//  Lablib
//
//  Created by John Maunsell on Thu May 08 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLIODeviceController.h" 
#import "LLIODeviceSettings.h" 

NSString *LLDataSourceKey = @"LL Data Source";
static LLIODeviceSettings	*sourceSettings;

@implementation LLIODeviceController

- (void)addIODevice:(id<LLIODevice>)newSource {

	[dataSources addObject:newSource];
	[newSource setSamplePeriodMS:samplePeriodMS];
	[newSource setTimestampTickPerMS:timestampTicksPerMS];
	[sourceSettings	insertMenuItem:[newSource name] atIndex:[dataSources indexOfObject:newSource]];
}

- (BOOL)canConfigureSourceWithIndex:(long)index {

	return [[dataSources objectAtIndex:index] canConfigure];
}

- (void)configureSourceWithIndex:(long)index {

	[[dataSources objectAtIndex:index] configure];
}

- (id<LLIODevice>)dataSource {

	long index;
	NSString *dataSourceName;
	
	if (dataSource == nil) {
		dataSourceName = [[NSUserDefaults standardUserDefaults] stringForKey:LLDataSourceKey];
		for (index = 0; index < [dataSources count]; index++) {
			if ([dataSourceName isEqualToString:[[dataSources objectAtIndex:index] name]]) {
				break;
			}
		}
		if (index >= [dataSources count]) {
			index = 0;
		}
		[self setDataSource:index];
	}
    return dataSource;
}

- (id<LLIODevice>)dataSourceWithCode:(long)code {

	return [dataSources objectAtIndex:code];
}

- (void)dealloc {

	[sourceSettings release];
	[dataSources release];
    [super dealloc];
}

- (void)disableTimestampBits:(unsigned short)bits {

	[dataSources makeObjectsPerformSelector:@selector(disableTimestampBits:) 
				withObject:[NSNumber numberWithUnsignedShort:bits]];
}

- (void)enableTimestampBits:(unsigned short)bits {

	[dataSources makeObjectsPerformSelector:@selector(enableTimestampBits:) 
				withObject:[NSNumber numberWithUnsignedShort:bits]];
}

- (id)initWithSamplePeriodMS:(double)samplePerMS timestampTicksPerMS:(double)timestampPerMS {
							
	if ((self = [super init]) != nil) {
		dataSources = [[NSMutableArray alloc] init];
		samplePeriodMS = samplePerMS;
		timestampTicksPerMS = timestampPerMS;
		sourceSettings = [[LLIODeviceSettings alloc] initWithController:self];
	}
    return self;
}

- (id<LLIODevice>)selectSource {

	long sourceIndex;
	BOOL previousState;
		
	previousState = [dataSource setDataEnabled:NO];
	sourceIndex = [sourceSettings selectSource:[dataSources indexOfObject:dataSource]];
	[self setDataSource:sourceIndex];
	[dataSource setDataEnabled:previousState];
    return dataSource;
}

- (void)setDataSource:(long)sourceIndex {

	dataSource = [dataSources objectAtIndex:sourceIndex];
    [[NSUserDefaults standardUserDefaults] setObject:[dataSource name] forKey:LLDataSourceKey];
}

@end
