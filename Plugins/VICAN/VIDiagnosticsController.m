//
//  VICANDiagnosticsController.m
//
//  Window with Diagnostics.
//
//  Copyright (c) 2012. All rights reserved.
//

#define NoGlobals

#import "VIDiagnosticsController.h"
#import "VI.h"
#import "UtilityFunctions.h"
#import "VIUtilities.h"

#define VIDiagnosticWindowVisibleKey      @"VIDiagnosticWindowVisible"
#define VIDiagnosticsAutosaveKey          @"VIDiagnosticsAutosave"
#define VIDiagnoisticsWindowVisibleKey    @"VIDiagnoisticsWindowVisible"

@implementation VIDiagnosticsController

- (void)addStimList:(NSArray *)stimList trialDesc:(TrialDesc)trial;
{
    StimDesc stimDesc;
	NSEnumerator *stimEnumerator;
	NSValue *value;

    [stimListLock lock];
    [stimListArray addObject:[NSArray arrayWithArray:stimList]];     // stimList is reused, so make a copy
    [stimListLock unlock];
    [trialDescLock lock];
    [trialDescArray addObject:[NSValue valueWithBytes:&trial objCType:@encode(TrialDesc)]];
    [trialDescLock unlock];
    [stimListTable reloadData];
//    [stimListTable scrollRowToVisible:[stimListArray count] - 1];
//    NSLog(@"Scrolling list to row %d", [stimListArray count] - 1);
	stimEnumerator = [stimList objectEnumerator];
	while (value = [stimEnumerator nextObject]) {					// For each stimulus
		[value getValue:&stimDesc];
        if (stimDesc.listTypes[kGabor0] == kValidStim && stimDesc.listTypes[kGabor1] == kValidStim && 
                                                         stimDesc.listTypes[kGaborFar0] == kValidStim &&
                                                         stimDesc.listTypes[kGaborFar1] == kValidStim) {
            stimCounts[stimDesc.attendState]
                                    [stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1]]++;
        }
    }
    [countTable reloadData];
}

- (id)countTableObject:(NSTableColumn *)tableColumn row:(int)row;
{
    long columnIndex;
    NSString *string;
    NSString *conditionStrings[] = {@"In*/In", @"In/In*", @"In/In/0*", @"In/In/1*", 
                                    @"In*/Out", @"In/Out*", @"In/Out/0*", @"In/Out/1*"};
    
    if ([tableColumn.identifier isEqualToString:@"State"]) {
        return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%2d", row] 
                                                attributes:fontAttrCenter] autorelease];
    }
    if ([tableColumn.identifier isEqualToString:@"Condition"]) {
        return [[[NSAttributedString alloc] initWithString:conditionStrings[row] attributes:fontAttrCenter] autorelease];
    }

    columnIndex = [tableColumn.identifier intValue];
    if (columnIndex >= 0 && columnIndex <= kStimPerState) {
        string = [NSString stringWithFormat:@"%ld", stimCounts[row][columnIndex]];
    }
    else {
        string = nil;
    }
    return [[[NSAttributedString alloc] initWithString:string attributes:fontAttrCenter] autorelease];
}

- (void)countTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{    
    if ([tableColumn.identifier isEqualToString:@"State"] || [tableColumn.identifier isEqualToString:@"Condition"]) {
        [cell setDrawsBackground:YES]; 
        [cell setBackgroundColor:[stateColors[row] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]]];
        return;
    }
    [cell setBackgroundColor:[NSColor controlHighlightColor]];
}

- (void)dealloc;
{
    [stimListLock lock];
    [stimListArray dealloc];
    stimListArray = nil;
    [stimListLock  unlock];
    [stimListLock  dealloc];
    [trialDescLock lock];
    [trialDescArray dealloc];
    trialDescArray = nil;
    [trialDescLock unlock];
    [trialDescLock dealloc];
    [fontAttrCenter release];
    [fontAttrRight release];
    [super dealloc];
}
    
- (id)init;
{
    if ((self = [super initWithWindowNibName:@"VIDiagnosticsController"]) != nil) {
        stimListArray = [[NSMutableArray alloc] init];
        stimListLock = [[NSLock alloc] init];
        trialDescArray = [[NSMutableArray alloc] init];
        trialDescLock = [[NSLock alloc] init];
        fontAttrCenter = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                                          alignment:NSCenterTextAlignment tailIndex:-12];
        [fontAttrCenter retain];
        fontAttrRight = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                                          alignment:NSRightTextAlignment tailIndex:-12];
        [fontAttrRight retain];
        [self window];							// Force the window to load now
   }
    return self;
}

- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent;
{    
	NSMutableParagraphStyle *para; 
    NSMutableDictionary *attr;
    
    para = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [para setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [para setAlignment:align];
//    [para setTailIndent:indent];
    
    attr = [[[NSMutableDictionary alloc] init] autorelease];
    [attr setObject:font forKey:NSFontAttributeName];
    [attr setObject:para forKey:NSParagraphStyleAttributeName];
    return attr;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
    long rows;
    
    if (tableView == stimListTable) {
        [stimListLock lock];
        rows = [stimListArray count];
        [stimListLock unlock];
    }
    else {
        rows = kNumStates;
    }
    return rows;
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long state, stim;
    
    for (state = 0; state < kNumStates; state++) {
        for (stim = 0; stim < kStimPerState; stim++) {
            stimCounts[state][stim] = 0;
        }
    }
    [countTable reloadData];

    [stimListLock lock];
	[stimListArray removeAllObjects];
    [stimListLock unlock];
    [trialDescLock lock];
	[trialDescArray removeAllObjects];
    [trialDescLock unlock];
	[stimListTable reloadData];
}

// Return an NSAttributedString for a cell in the percent performance table

// Display the color patches showing the EOT color coding, and highlight the text for the last EOT type

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    if (tableView == stimListTable) {
        return [self stimListTableObject:tableColumn row:row];
    }
    else if (tableView == countTable) {
        return [self countTableObject:tableColumn row:row];
    }
    else {
        return nil;
    }
}

- (id)stimListTableObject:(NSTableColumn *)tableColumn row:(int)row;
{
    long entryNum;
    NSString *string, *trialChar;
 	NSArray	*stimList;
    StimDesc stimDesc;
    TrialDesc trial;
    
    if ([tableColumn.identifier isEqualToString:@"listNum"]) {
        return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%2d", row] 
                                                attributes:fontAttrCenter] autorelease];
    }
    [trialDescLock lock];
    [[trialDescArray objectAtIndex:row] getValue:&trial];
    [trialDescLock unlock];
    if ([tableColumn.identifier isEqualToString:@"type"]) {
        if (trial.catchTrial) {
            trialChar = @"C";
        }
        else if (trial.instructTrial) {
            trialChar = @"I";
        }
        else {
            trialChar = @"";
        }
        return [[[NSAttributedString alloc] initWithString:trialChar attributes:fontAttrCenter] autorelease];
    }
    [stimListLock lock];
    stimList = [stimListArray objectAtIndex:row];
    [stimListLock unlock];
    entryNum = [tableColumn.identifier intValue];
    if (entryNum >= [stimList count]) {
        return nil;
    }
    string = [VIUtilities stringForStimDescEntry:stimList entryIndex:entryNum];
    [[stimList objectAtIndex:entryNum] getValue:&stimDesc];
//    string = @"";
//    for (stimIndex = 0; stimIndex < kStimLocs; stimIndex++) {
//        if (stimDesc.listTypes[stimIndex] == kTargetStim) {
//            if (stimIndex == stimDesc.attendLoc) {
//                string = [NSString stringWithFormat:@"T%@", string];
//            }
//            else  {
//                string = [NSString stringWithFormat:@"%@D", string];
//            }
//        }
//    }
//    if ([string isEqualToString:@""]) {
//        stimIndex = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];
//        string = [NSString stringWithFormat:@"%2ld", stimIndex];       
//    }
    return [[[NSAttributedString alloc] initWithString:string attributes:fontAttrCenter] autorelease];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
{
	return NO;
}

// Display the color patches showing the EOT color coding, and highlight the text for the last EOT type

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn
              row:(int)row;
{
    if (tableView == stimListTable) {
        [self stimListTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row];
    }
    else if (tableView == countTable) {
        [self countTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row];
    }
}    
   
- (void)stimListTableWillDisplay:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{    
    TrialDesc rowTrial;
    long t, entryNum;
    BOOL valid;
    StimDesc stimDesc;
 	NSArray	*stimList;
       
    if ([tableColumn.identifier isEqualToString:@"type"]) {
        [cell setDrawsBackground:YES];
        [cell setBackgroundColor:[NSColor controlHighlightColor]];
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"listNum"]) {
        [trialDescLock lock];
        [[trialDescArray objectAtIndex:row] getValue:&rowTrial];
        [trialDescLock unlock];
        [cell setDrawsBackground:YES];
        [cell setBackgroundColor:
        [stateColors[rowTrial.attendState] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]]];
        return;
    }
    entryNum = [tableColumn.identifier intValue];
    [stimListLock lock];
    stimList = [stimListArray objectAtIndex:row];
    [stimListLock unlock];
    if (entryNum >= [stimList count]) {                         // beyond the end of the list for this row
        [cell setDrawsBackground:NO];
        return;
    }
    [[stimList objectAtIndex:entryNum] getValue:&stimDesc];     // get stimulus description
    for (t = 0; t < kStimLocs; t++) {
        if (!(valid = (stimDesc.listTypes[t] == kValidStim))) {
            break;
        }
    }
    [cell setDrawsBackground:valid]; 
    if (valid) {
        [trialDescLock lock];
        [[trialDescArray objectAtIndex:row] getValue:&rowTrial];
        [trialDescLock unlock];
        [cell setBackgroundColor:
                    [stateColors[rowTrial.attendState] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]]];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[[task defaults] setObject:[NSNumber numberWithBool:YES] forKey:VIDiagnosticWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void)windowDidLoad;
{
	[[self window] setFrameUsingName:VIDiagnosticsAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:VIDiagnosticWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
    [super windowDidLoad];
}

- (BOOL)windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] forKey:VIDiagnosticWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

@end
