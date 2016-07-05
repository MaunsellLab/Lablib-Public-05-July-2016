//
//  MTCSummaryController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "MTCSummaryController.h"
#import "MTC.h"
#import "UtilityFunctions.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored		// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define	kXTickSpacing			100

enum {kBlankRow0 = kLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *MTCSummaryWindowBrokeKey = @"MTCSummaryWindowBroke";
NSString *MTCSummaryWindowComputerKey = @"MTCSummaryWindowComputer";
NSString *MTCSummaryWindowCorrectKey = @"MTCSummaryWindowCorrect";
NSString *MTCSummaryWindowDateKey = @"MTCSummaryWindowDate";
NSString *MTCSummaryWindowFailedKey = @"MTCSummaryWindowFailed";
NSString *MTCSummaryWindowIgnoredKey = @"MTCSummaryWindowIgnored";
NSString *MTCSummaryWindowTotalKey = @"MTCSummaryWindowTotal";
NSString *MTCSummaryWindowWrongKey = @"MTCSummaryWindowWrong";

@implementation MTCSummaryController

- (void)dealloc {

	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:MTCSummaryWindowDateKey];
	[[task defaults] setInteger:dayEOTs[kEOTBroke] forKey:MTCSummaryWindowBrokeKey];
	[[task defaults] setInteger:dayEOTs[kEOTCorrect] forKey:MTCSummaryWindowCorrectKey];
	[[task defaults] setInteger:dayEOTs[kEOTFailed] forKey:MTCSummaryWindowFailedKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored] forKey:MTCSummaryWindowIgnoredKey];
	[[task defaults] setInteger:dayEOTs[kEOTWrong] forKey:MTCSummaryWindowWrongKey];
	[[task defaults] setInteger:dayEOTTotal forKey:MTCSummaryWindowTotalKey];
	[[task defaults] setInteger:dayComputer forKey:MTCSummaryWindowComputerKey];
    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init;
{
	double timeNow, timeStored;
    
    if ((self = [super initWithWindowNibName:@"MTCSummaryController" defaults:[task defaults]]) != nil) {
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
        [recentPlot setData:recentEOTs];
    
		lastEOTCode = -1;
		
		timeStored = [[task defaults] floatForKey:MTCSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [[task defaults] integerForKey:MTCSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [[task defaults] integerForKey:MTCSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [[task defaults] integerForKey:MTCSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [[task defaults] integerForKey:MTCSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [[task defaults] integerForKey:MTCSummaryWindowWrongKey];
			dayEOTTotal = [[task defaults] integerForKey:MTCSummaryWindowTotalKey];
			dayComputer = [[task defaults] integerForKey:MTCSummaryWindowComputerKey];
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

- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row {

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
                    string = [NSString stringWithFormat:@"%@:", 
								[LLStandardDataEvents trialEndName:kLastEOTTypeDisplayed - row]];
                    break;
            }
            break;
        case kDayColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%d", dayEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%d", dayEOTs[kEOTCorrect]];
            }
            else if (dayEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%d", dayComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%d%%", 
							(long)round(dayEOTs[kLastEOTTypeDisplayed - row] * 100.0 / dayEOTTotal)];
            }
            break;
       case kRecentColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%d", recentEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%d", recentEOTs[kEOTCorrect]];
            }
            else if (recentEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%d", recentComputer];
			}
           else {
				if (recentEOTTotal == 0) {
					string = @"";
				}
				else {
					string = [NSString stringWithFormat:@"%d%%", 
							(long)round(recentEOTs[kLastEOTTypeDisplayed - row] * 100.0 / recentEOTTotal)];
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

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn 					row:(int)rowIndex {

	long column;
	
	if (tableView == percentTable) { 
		column = [[tableColumn identifier] intValue];
		if (column == kColorColumn) {
			[cell setDrawsBackground:YES]; 
			if (rowIndex <= kLastEOTTypeDisplayed) {
				[cell setBackgroundColor:[LLStandardDataEvents eotColor:kLastEOTTypeDisplayed - rowIndex]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
		else {
			if (!newTrial && (lastEOTCode >= 0) && (lastEOTCode == (kLastEOTTypeDisplayed - rowIndex))) {
				[cell setBackgroundColor:[NSColor controlHighlightColor]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
    }
}

- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row {

    long column, remainingTrials, doneTrials;
    double timeLeftS;
    NSAttributedString *cellContents;
    NSString *string;
	StimParams *pStimParam;
	BlockStatus *pBS = &blockStatus;

// Do nothing if the data buffers have nothing in them

    if ((column = [[tableColumn identifier] intValue]) != 0) {
        return @"";
    }
	
	pStimParam = &stimParams;
    switch (row) {
        case 0:
			string = [NSString stringWithFormat:@"Attend side %d %@",  pBS->attendLoc, 
						(trial.instructTrial) ? @"(Instruction trial)" : @""];
			break;
        case 1:
			string = @"";
            break;
        case 2:
            string = [NSString stringWithFormat:@"Presentation %d of %d", 
                MIN(pBS->presentationsPerLoc, pBS->presentationsDoneThisLoc + 1), pBS->presentationsPerLoc];
            break;
        case 3:
            string = [NSString stringWithFormat:@"Side %d of %d", pBS->locsDoneThisBlock + 1, 
									pBS->locsPerBlock];
            break;
        case 4:
            string = [NSString stringWithFormat:@"Block %d of %d", pBS->blocksDone + 1, 
									pBS->blockLimit];
			break;
        case 5:
            remainingTrials =  MAX(0, (pBS->blockLimit - pBS->blocksDone) * 
					(pBS->presentationsPerLoc * pBS->locsPerBlock) - 
					(pBS->locsDoneThisBlock * pBS->presentationsPerLoc + pBS->presentationsDoneThisLoc));
            doneTrials = (pBS->blocksDone * pBS->locsPerBlock + pBS->locsDoneThisBlock)
						* pBS->presentationsPerLoc + pBS->presentationsDoneThisLoc;
            if (doneTrials == 0) {
                string = [NSString stringWithFormat:@"Remaining: %d stimuli", remainingTrials];
            }
            else {
                timeLeftS = ([LLSystemUtil getTimeS] - lastStartTimeS + accumulatedRunTimeS)
													/ doneTrials * remainingTrials;
                if (timeLeftS < 60.0) {
                    string = [NSString stringWithFormat:@"Remaining: %d stimuli (%.1f s)", 
                                remainingTrials, timeLeftS];
                }
                else if (timeLeftS < 3600.0) {
                    string = [NSString stringWithFormat:@"Remaining: %d stimuli (%.1f m)", 
                                remainingTrials, timeLeftS / 60.0];
                }
                else {
                    string = [NSString stringWithFormat:@"Remaining: %d stimuli (%.1f h)", 
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

- (void) contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&stimParams];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
    recentComputer = recentEOTTotal = 0;
    for (index = 0; index <= kLastEOTTypeDisplayed; index++) {
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

- (void) taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime {

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

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&eotCode];
    if (eotCode <= kLastEOTTypeDisplayed) {
        recentEOTs[eotCode]++;
        recentEOTTotal++;  
        dayEOTs[eotCode]++;
        dayEOTTotal++;  
    }
    newTrial = NO;
	lastEOTCode = eotCode;
	[eotHistory addEOT:eotCode];
    [percentTable reloadData];
	[trialTable reloadData];
	[dayPlot setNeedsDisplay:YES];
	[recentPlot setNeedsDisplay:YES];
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trial];
    newTrial = YES;
	[trialTable reloadData];
    [percentTable reloadData];
}

@end
