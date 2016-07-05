//
//  V4CANDiagnosticsController.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCAN.h"
#import "VCANStateSystem.h"

@interface VCANDiagnosticsController : NSWindowController <NSWindowDelegate> {
    
    NSDictionary		*fontAttrCenter;
    NSDictionary		*fontAttrRight;
    long                stimCounts[kNumStates][kStimPerState];
    NSMutableArray      *stimListArray;
    NSLock              *stimListLock;
    NSMutableArray      *trialDescArray;
    NSLock              *trialDescLock;

    IBOutlet			NSTableView *countTable;
    IBOutlet			NSTableView *stimListTable;
}

- (void)countTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)countTableObject:(NSTableColumn *)tableColumn row:(int)row;
- (void)addStimList:(NSArray *)stimList trialDesc:(TrialDesc)trial;
- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent;
- (id)stimListTableObject:(NSTableColumn *)tableColumn row:(int)row;
- (void)stimListTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end
