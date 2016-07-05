//
//  VCANSummaryController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Copyright (c) 2012. All rights reserved.
//

#define NoGlobals

#import "VCANSummaryController.h"
#import "VCAN.h"
#import "UtilityFunctions.h"

//enum {kEOTCorrect = 0, kEOTWrong, kEOTFailed, kEOTBroke, kEOTIgnored, kEOTQuit, kEOTTypes};
//enum {kEOTEarly = kEOTTypes, kEOTDistractor, kExtendedEOTTypes};

#define kEOTDisplayTimeS		1.0
//#define kLastEOTTypeDisplayed   kEOTIgnored		// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kNumEOTDisplayed + 5) // extra for blank rows, total, etc.
#define	kXTickSpacing			100

enum {kBlankRow0 = kNumEOTDisplayed, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *VCANSummaryWindowBrokeKey = @"VCANSummaryWindowBroke";
NSString *VCANSummaryWindowComputerKey = @"VCANSummaryWindowComputer";
NSString *VCANSummaryWindowCorrectKey = @"VCANSummaryWindowCorrect";
NSString *VCANSummaryWindowDateKey = @"VCANSummaryWindowDate";
NSString *VCANSummaryWindowDistractedKey = @"VCANSummaryWindowDistracted";
NSString *VCANSummaryWindowEarlyKey = @"VCANSummaryWindowEarly";
NSString *VCANSummaryWindowFailedKey = @"VCANSummaryWindowFailed";
NSString *VCANSummaryWindowIgnoredKey = @"VCANSummaryWindowIgnored";
NSString *VCANSummaryWindowTotalKey = @"VCANSummaryWindowTotal";
NSString *VCANSummaryWindowWrongKey = @"VCANSummaryWindowWrong";

NSString *displayedEOTNames[kNumEOTDisplayed] = {@"Correct", @"Wrong", @"Failed", @"Broke", @"Ignored", @"Early", 
		@"Distracted"};

long  mapToDisplayedEOT[kExtendedEOTTypes] = {0, 1, 2, 3, 4, -1, 5, 6};

@implementation VCANSummaryController

- (void)dealloc {

	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:VCANSummaryWindowDateKey];
	[[task defaults] setInteger:dayEOTs[kEOTBroke] forKey:VCANSummaryWindowBrokeKey];
	[[task defaults] setInteger:dayEOTs[kEOTCorrect] forKey:VCANSummaryWindowCorrectKey];
	[[task defaults] setInteger:dayEOTs[kEOTFailed] forKey:VCANSummaryWindowFailedKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored] forKey:VCANSummaryWindowIgnoredKey];
	[[task defaults] setInteger:dayEOTs[kEOTWrong] forKey:VCANSummaryWindowWrongKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored + 1] forKey:VCANSummaryWindowEarlyKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored + 1] forKey:VCANSummaryWindowDistractedKey];
	[[task defaults] setInteger:dayEOTTotal forKey:VCANSummaryWindowTotalKey];
	[[task defaults] setInteger:dayComputer forKey:VCANSummaryWindowComputerKey];
    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init;
{
	double timeNow, timeStored;
	
    if ((self = [super initWithWindowNibName:@"VCANSummaryController" defaults:[task defaults]]) != nil) {
		[percentTable reloadData];
        fontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:-12];
        [fontAttr retain];
        labelFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:0];
        [labelFontAttr retain];
        leftFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSLeftTextAlignment tailIndex:0];
        [leftFontAttr retain];
        
        [dayPlot setData:dayEOTs];
		[dayPlot setEOTTypes:kNumEOTDisplayed];
        [recentPlot setData:recentEOTs];
 		[recentPlot setEOTTypes:kNumEOTDisplayed];
   
		lastEOTCode = -1;
		
		timeStored = [[task defaults] floatForKey:VCANSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [[task defaults] integerForKey:VCANSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [[task defaults] integerForKey:VCANSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [[task defaults] integerForKey:VCANSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [[task defaults] integerForKey:VCANSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [[task defaults] integerForKey:VCANSummaryWindowWrongKey];
			dayEOTs[kEOTIgnored + 1] = [[task defaults] integerForKey:VCANSummaryWindowEarlyKey];
			dayEOTs[kEOTIgnored + 2] = [[task defaults] integerForKey:VCANSummaryWindowDistractedKey];
			dayEOTTotal = [[task defaults] integerForKey:VCANSummaryWindowTotalKey];
			dayComputer = [[task defaults] integerForKey:VCANSummaryWindowComputerKey];
		}
    }
    return self;
}

- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent {

	NSMutableParagraphStyle *para; 
    NSMutableDictionary *attr;
    
        para = [[NSMutableParagraphStyle alloc] init];
        [para setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        [para setAlignment:align];
        [para setTailIndent:indent];
        
        attr = [[NSMutableDictionary alloc] init];
        [attr setObject:font forKey:NSFontAttributeName];
        [attr setObject:para forKey:NSParagraphStyleAttributeName];
        [attr autorelease];
        [para release];
        return attr;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return kTableRows;
}

// Return an NSAttributedString for a cell in the percent performance table

- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row;
{
    long column;
    NSString *string;
	NSDictionary *attr = fontAttr;
 
    if (row == kBlankRow0 || row == kBlankRow1) {		// the blank rows
        return @" ";
    }
    column = [[tableColumn identifier] intValue];
    switch (column) {
		case kColorColumn:
            string = @" ";
			break;
        case kEOTColumn:
			attr = labelFontAttr;
            switch (row) {
                case kTotalRow:
                    string = @"Total:";
                    break;
				case kRewardsRow:
					string = @"Rewards:";
					break;
				case kComputerRow:					// row for computer failures
                    string = @"Computer:";
					break;
                default:
                    string = [NSString stringWithFormat:@"%@:", displayedEOTNames[kNumEOTDisplayed - row - 1]];
                    break;
            }
            break;
        case kDayColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", dayEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", dayEOTs[kEOTCorrect]];
            }
            else if (dayEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", dayComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(dayEOTs[kNumEOTDisplayed - row - 1] * 100.0 / dayEOTTotal)];
            }
            break;
       case kRecentColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", recentEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", recentEOTs[kEOTCorrect]];
            }
            else if (recentEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", recentComputer];
			}
           else {
				if (recentEOTTotal == 0) {
					string = @"";
				}
				else {
					string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(recentEOTs[kNumEOTDisplayed - row - 1] * 100.0 / recentEOTTotal)];
				}
            }
            break;
        default:
            string = @"???";
            break;
    }
	return [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {

    if (tableView == percentTable) {
        return [self percentTableColumn:tableColumn row:row];
    }
    else if (tableView == trialTable) {
        return [self trialTableColumn:tableColumn row:row];
    }
    else {
        return @"";
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
{
	return NO;
}

// Display the color patches showing the EOT color coding, and highlight the text for the last EOT type

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn
													row:(int)rowIndex {

	long column;
	
	if (tableView == percentTable) { 
		column = [[tableColumn identifier] intValue];
		if (column == kColorColumn) {
			[cell setDrawsBackground:YES]; 
			if (rowIndex < kNumEOTDisplayed) {
				[cell setBackgroundColor:[LLStandardDataEvents eotColor:kNumEOTDisplayed - rowIndex - 1]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
		else {
			if (!newTrial && (lastEOTCode >= 0) && (lastEOTCode == (kNumEOTDisplayed - rowIndex - 1))) {
				[cell setBackgroundColor:[NSColor controlHighlightColor]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
    }
}

- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row;
{
    long column, remainingTrials, doneTrials;
    double timeLeftS;
    NSAttributedString *cellContents;
    NSString *string;
	BlockStatus *pBS = &blockStatus;
	NSString *stateLabels[] = { @"In/In Attend In 0", @"In/In Attend In 1", @"In/In Attend Far 0", 
        @"In/In Attend Far 1", @"In/Out Attend In 0", @"In/Out Attend Out 1", @"In/Out Attend Far 0", 
        @"In/Out Attend Far 1"};

// Do nothing if the data buffers have nothing in them

    if ((column = [[tableColumn identifier] intValue]) != 0) {
        return @"";
    }
	if (pBS->blockLimit == 0) {
		return @"";
	}
    switch (row) {
        case 0:
            string = [NSString stringWithFormat:@"%@ (%.f%% change%@)", stateLabels[trial.attendState],
						  fabs(trial.targetContrastChangePC[trial.attendLoc]),
						  (trial.instructTrial) ? @", Instruction" : @""];
			break;
        case 1:
			string = @"";
            break;
        case 2:
            string = [NSString stringWithFormat:@"Presentation %ld of %ld %@",
                MIN(pBS->presPerState, pBS->presDoneThisState + 1), pBS->presPerState,
				(pBS->presPerState == 0) ? @"" : [NSString stringWithFormat:@"(%ld reps of %ld stimuli)",
				pBS->presPerState / pBS->stimPerState, pBS->stimPerState]];
            break;
        case 3:
            string = [NSString stringWithFormat:@"Attention State %ld of %ld", pBS->statesDoneThisBlock + 1, 
						pBS->statesPerBlock];
            break;
        case 4:
            string = [NSString stringWithFormat:@"Block %ld of %ld (%ld repetitions)", pBS->blocksDone + 1, 
					  pBS->blockLimit, pBS->blockLimit * pBS->statesPerBlock * pBS->presPerState];
			break;
        case 5:
            remainingTrials =  MAX(0, (pBS->blockLimit - pBS->blocksDone) * (pBS->presPerState * pBS->statesPerBlock) - 
					(pBS->statesDoneThisBlock * pBS->presPerState + pBS->presDoneThisState));
            doneTrials = (pBS->blocksDone * pBS->statesPerBlock + pBS->statesDoneThisBlock)
						* pBS->presPerState + pBS->presDoneThisState;
            if (doneTrials == 0) {
                string = [NSString stringWithFormat:@"Remaining: %ld stimuli", remainingTrials];
            }
            else {
                timeLeftS = ([LLSystemUtil getTimeS] - lastStartTimeS + accumulatedRunTimeS)
													/ doneTrials * remainingTrials;
                if (timeLeftS < 60.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f s)", 
                                remainingTrials, timeLeftS];
                }
                else if (timeLeftS < 3600.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f m)", 
                                remainingTrials, timeLeftS / 60.0];
                }
                else {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f h)", 
                                remainingTrials, timeLeftS / 3600.0];
                }
            }
            break;
        default:
            string = @"???";
            break;
    }
    cellContents = [[NSAttributedString alloc] initWithString:string attributes:leftFontAttr];
	[cellContents autorelease];
    return cellContents;
}

// Methods related to data events follow:

- (void)blockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&blockStatus];
}

- (void)extendedEOT:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long extEotCode;
	long mappedCode;
    	
	[eventData getBytes:&extEotCode];
	mappedCode = mapToDisplayedEOT[extEotCode];
	if (mappedCode >= 0) {
		recentEOTs[mappedCode]++;
		recentEOTTotal++;  
		dayEOTs[mappedCode]++;
		dayEOTTotal++; 
		[dayPlot setNeedsDisplay:YES];
		[recentPlot setNeedsDisplay:YES];
		[eotHistory addEOT:mappedCode];
	}
    newTrial = NO;
	lastEOTCode = mappedCode;
	
    [percentTable reloadData];
	[trialTable reloadData];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
    recentComputer = recentEOTTotal = 0;
    for (index = 0; index <= kNumEOTDisplayed; index++) {
        recentEOTs[index] = 0;
    }
    accumulatedRunTimeS = 0;
    if (taskMode == kTaskRunning) {
        lastStartTimeS = [LLSystemUtil getTimeS];
    }
	[eotHistory reset];
	[percentTable reloadData];
	[trialTable reloadData];
}

- (void)taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&taskMode];
    switch (taskMode) {
        case kTaskRunning:
            lastStartTimeS = [LLSystemUtil getTimeS];
            break;
        case kTaskStopping:
            accumulatedRunTimeS += [LLSystemUtil getTimeS] - lastStartTimeS;
            break;
        default:
            break;
    }
}

- (void) trialCertify:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long certifyCode; 
	
	[eventData getBytes:&certifyCode];
    if (certifyCode != 0) { // -1 because computer errors stored separately
        recentComputer++;  
        dayComputer++;  
    }
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trial];
    newTrial = YES;
	[trialTable reloadData];
    [percentTable reloadData];
}

@end
