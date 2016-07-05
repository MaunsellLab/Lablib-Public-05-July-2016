//
//  LLIODeviceController.h 
//  Lablib
//
//  Created by John Maunsell on Thu May 08 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLIODevice.h"

extern NSString *LLDataSourceKey;
@interface LLIODeviceController : NSObject {

@protected
	id<LLIODevice>		dataSource;
	NSMutableArray		*dataSources;
	double				samplePeriodMS;
	double				timestampTicksPerMS;
}
               
/*!
  @method addIODevice
  @discussion Use addIODevice to add a new IO Device to the set of active devices.
  @param newSource The source to be added.  It must adhere to the LLIODevice protocol. 
*/

- (void)addIODevice:(id<LLIODevice>)newSource;
- (BOOL)canConfigureSourceWithIndex:(long)index;
- (void)configureSourceWithIndex:(long)index;
- (id<LLIODevice>)dataSource;
- (id<LLIODevice>)dataSourceWithCode:(long)code;
- (void)disableTimestampBits:(unsigned short)bits;
- (void)enableTimestampBits:(unsigned short)bits;
- (id)initWithSamplePeriodMS:(double)samplePerMS timestampTicksPerMS:(double)timestampPerMS;
- (id<LLIODevice>)selectSource;
- (void)setDataSource:(long)sourceCode;

@end
