//
//  SCSummaryController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

// enum {kEOTCorrect = 0, kEOTWrong, kEOTFailed, kEOTBroke, kEOTIgnored, kEOTQuit, kEOTTypes};
//enum {kMyEOTCorrect = 0, kMyEOTMissed, kMyEOTEarlyToValid, kMyEOTEarlyToInvalid, kMyEOTBroke, kMyEOTIgnored,
//		kMyEOTQuit, kMyEOTTypes};

#import "SCSummaryController.h"
#import "SC.h"
#import "UtilityFunctions.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored				// Count everything up to kEOTIgnored
#define kMyLastEOTTypeDisplayed  kMyEOTIgnored				// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kMyLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define kTrialTableRows			6
#define	kXTickSpacing			100

enum {kBlankRow0 = kMyLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *SCSummaryWindowBrokeKey = @"SCSummaryWindowBroke";
NSString *SCSummaryWindowComputerKey = @"SCSummaryWindowComputer";
NSString *SCSummaryWindowCorrectKey = @"SCSummaryWindowCorrect";
NSString *SCSummaryWindowDateKey = @"SCSummaryWindowDate";
NSString *SCSummaryWindowFailedKey = @"SCSummaryWindowFailed";
NSString *SCSummaryWindowIgnoredKey = @"SCSummaryWindowIgnored";
NSString *SCSummaryWindowTotalKey = @"SCSummaryWindowTotal";
NSString *SCSummaryWindowWrongKey = @"SCSummaryWindowWrong";

NSString *SCMySummaryBrokeKey = @"SCMySummaryBroke";
NSString *SCMySummaryCorrectKey = @"SCMySummaryCorrect";
NSString *SCMySummaryMissedKey = @"SCMySummaryMissed";
NSString *SCMySummaryIgnoredKey = @"SCMySummaryIgnored";
NSString *SCMySummaryEarlyToValidKey = @"SCMySummaryEarlyToValid";
NSString *SCMySummaryEarlyToInvalidKey = @"SCMySummaryEarlyToInvalid";
NSString *SCMySummaryTotalKey = @"SCMySummaryTotal";

@implementation SCSummaryController

- (void)dealloc;
{
	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:SCSummaryWindowDateKey];
	[[task defaults] setInteger:dayEOTs[kEOTBroke] forKey:SCSummaryWindowBrokeKey];
	[[task defaults] setInteger:dayEOTs[kEOTCorrect] forKey:SCSummaryWindowCorrectKey];
	[[task defaults] setInteger:dayEOTs[kEOTFailed] forKey:SCSummaryWindowFailedKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored] forKey:SCSummaryWindowIgnoredKey];
	[[task defaults] setInteger:dayEOTs[kEOTWrong] forKey:SCSummaryWindowWrongKey];
	[[task defaults] setInteger:dayEOTTotal forKey:SCSummaryWindowTotalKey];
	[[task defaults] setInteger:dayComputer forKey:SCSummaryWindowComputerKey];

	[[task defaults] setInteger:myDayEOTs[kEOTBroke] forKey:SCMySummaryBrokeKey];
	[[task defaults] setInteger:myDayEOTs[kEOTCorrect] forKey:SCMySummaryCorrectKey];
	[[task defaults] setInteger:myDayEOTs[kEOTFailed] forKey:SCMySummaryMissedKey];
	[[task defaults] setInteger:myDayEOTs[kEOTIgnored] forKey:SCMySummaryIgnoredKey];
	[[task defaults] setInteger:myDayEOTs[kEOTWrong] forKey:SCMySummaryEarlyToValidKey];
	[[task defaults] setInteger:myDayEOTs[kEOTWrong] forKey:SCMySummaryEarlyToInvalidKey];
	[[task defaults] setInteger:myDayEOTTotal forKey:SCMySummaryTotalKey];

    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init;
{
	double timeNow, timeStored;
    
    if ((self = [super initWithWindowNibName:@"SCSummaryController" defaults:[task defaults]]) != nil) {
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
		
		timeStored = [[task defaults] floatForKey:SCSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [[task defaults] integerForKey:SCSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [[task defaults] integerForKey:SCSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [[task defaults] integerForKey:SCSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [[task defaults] integerForKey:SCSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [[task defaults] integerForKey:SCSummaryWindowWrongKey];
			dayEOTTotal = [[task defaults] integerForKey:SCSummaryWindowTotalKey];
			dayComputer = [[task defaults] integerForKey:SCSummaryWindowComputerKey];

			myDayEOTs[kMyEOTBroke] = [[task defaults] integerForKey:SCMySummaryBrokeKey];
			myDayEOTs[kMyEOTCorrect] = [[task defaults] integerForKey:SCMySummaryCorrectKey];
			myDayEOTs[kMyEOTMissed] = [[task defaults] integerForKey:SCMySummaryMissedKey];
			myDayEOTs[kMyEOTIgnored] = [[task defaults] integerForKey:SCMySummaryIgnoredKey];
			myDayEOTs[kMyEOTEarlyToValid] = [[task defaults] integerForKey:SCMySummaryEarlyToValidKey];
			myDayEOTs[kMyEOTEarlyToInvalid] = [[task defaults] integerForKey:SCMySummaryEarlyToInvalidKey];
			myDayEOTTotal = [[task defaults] integerForKey:SCMySummaryTotalKey];
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

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
	if (tableView == trialTable) {
		return kTrialTableRows;
	}
	else {
		return kTableRows;
	}
}

// Return an NSAttributedString for a cell in the percent performance table

- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row {

    long column;
    NSString *string;
	NSDictionary *attr = fontAttr;
	NSString *eotStrings[] = {@"Correct", @"Missed", @"Early Val", @"Early Inval", @"Broke", @"Ignored"};
 
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
  //                  string = [NSString stringWithFormat:@"%@:", 
//								[LLStandardDataEvents trialEndName:kLastEOTTypeDisplayed - row]];
					string = eotStrings[kMyLastEOTTypeDisplayed - row];
                    break;
            }
            break;
        case kDayColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", myDayEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", myDayEOTs[kMyEOTCorrect]];
            }
            else if (myDayEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", dayComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(myDayEOTs[kMyLastEOTTypeDisplayed - row] * 100.0 / myDayEOTTotal)];
            }
            break;
       case kRecentColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", myRecentEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", myRecentEOTs[kEOTCorrect]];
            }
            else if (recentEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", recentComputer];
			}
           else {
				if (myRecentEOTTotal == 0) {
					string = @"";
				}
				else {
					string = [NSString stringWithFormat:@"%ld%%",
							(long)round(myRecentEOTs[kMyLastEOTTypeDisplayed - row] * 100.0 / myRecentEOTTotal)];
				}
            }
            break;
        default:
            string = @"???";
            break;
    }
	return [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
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
	long colorMapping[] = {4, 3, 5, 1, 2, 0};
	
	if (tableView != percentTable) {
		return;
	}
	column = [[tableColumn identifier] intValue];
	if (column == kColorColumn) {
		[cell setDrawsBackground:YES]; 
		if (rowIndex <= kMyLastEOTTypeDisplayed) {
			[cell setBackgroundColor:[LLStandardDataEvents eotColor:colorMapping[rowIndex]]];
		}
		else {
			[cell setBackgroundColor:[NSColor whiteColor]];
		}
	}
	else {
		if (!newTrial && (lastEOTCode >= 0) && (lastEOTCode == (kMyLastEOTTypeDisplayed - rowIndex))) {
			[cell setBackgroundColor:[NSColor controlHighlightColor]];
		}
		else {
			[cell setBackgroundColor:[NSColor whiteColor]];
		}
	}
}

- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row;
{
    long index, repsDone, repsPerSide, column, remainingTrials, doneTrials;
    double timeLeftS;
    NSAttributedString *cellContents;
    NSString *string;
	BlockStatus *pBS = &blockStatus;
	
	static BOOL initialized = NO;
	
	initialized = (initialized | newTrial);

// Do nothing if the data buffers have nothing in them

    if ((column = [[tableColumn identifier] intValue]) != 0) {
        return @"";
    }
	
    switch (row) {
        case 0:
            if (!initialized) {
                string = @" ";
            }
			else {
				if (trial.catchTrial) {
					string = [NSString stringWithFormat:@"%s trial catch trial", newTrial ? "This" : "Last"];
				}
				else if (trial.instructTrial) {
					string = [NSString stringWithFormat:@"%s trial %.2f alpha change (instruction)", 
							newTrial ? "This" : "Last", trial.orientationChangeDeg];
				}
				else {
					string = [NSString stringWithFormat:@"%s trial %.2f alpha change%@", newTrial ? "This" : "Last",
							trial.orientationChangeDeg, (trial.validTrial) ? @"" : @" (invalid)"];
				}
			}
			break;
        case 1:
			string = @"";
			break;
        case 2:
			repsPerSide = repsDone = 0;
			for (index = 0; index < pBS->changes; index++) {
				repsPerSide += pBS->validReps[index] + pBS->invalidReps[index];
				repsDone += pBS->validRepsDone[index] + pBS->invalidRepsDone[index];
			}
            string = [NSString stringWithFormat:@"Trial %ld of %ld", repsDone + 1, repsPerSide];
            break;
		case 3: 
            string = [NSString stringWithFormat:@"Side %ld of 2", pBS->sidesDone + 1];
            break;
        case 4:
            string = [NSString stringWithFormat:@"Block %ld of %ld", pBS->blocksDone + 1, pBS->blockLimit];
			break;
        case 5:
			repsPerSide = repsDone = 0;
			for (index = 0; index < pBS->changes; index++) {
				repsPerSide += pBS->validReps[index] + pBS->invalidReps[index];
				repsDone += pBS->validRepsDone[index] + pBS->invalidRepsDone[index];
			}
           remainingTrials =  MAX(0, (pBS->blockLimit - pBS->blocksDone) * repsPerSide * kLocations
						- pBS->sidesDone * repsPerSide - repsDone);
            doneTrials = pBS->blocksDone * repsPerSide * kLocations
							+ pBS->sidesDone * repsPerSide + repsDone;
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

- (void) dirChangeStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&stimParams];
}

// Save our trial end code for processing when the final trial end occurs.  The EOT plots
// are driven off Lablib EOT codes, which are taken from the trialEnd event.  The myTrialEnd
// codes are used only for the percentage recored.

- (void) myTrialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode;
	
	[eventData getBytes:&eotCode];
	lastEOTCode = eotCode;

    if (eotCode <= kMyLastEOTTypeDisplayed) {
        myRecentEOTs[eotCode]++;
        myRecentEOTTotal++;  
        myDayEOTs[eotCode]++;
        myDayEOTTotal++;  
    }
    [percentTable reloadData];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
    recentComputer = recentEOTTotal = myRecentEOTTotal = 0;
    for (index = 0; index <= kLastEOTTypeDisplayed; index++) {
        recentEOTs[index] = 0;
    }
    for (index = 0; index <= kMyLastEOTTypeDisplayed; index++) {
        myRecentEOTs[index] = 0;
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
    if (certifyCode != 0L) { // -1 because computer errors stored separately
        recentComputer++;  
        dayComputer++;  
    }
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode;
	
	[eventData getBytes:&eotCode];

	if (eotCode <= kLastEOTTypeDisplayed) {
        recentEOTs[eotCode]++;
        recentEOTTotal++;  
        dayEOTs[eotCode]++;
        dayEOTTotal++;  
    }
    newTrial = NO;
	[eotHistory addEOT:eotCode];
	[trialTable reloadData];
	[dayPlot setNeedsDisplay:YES];
	[recentPlot setNeedsDisplay:YES];
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&trial];
    newTrial = YES;
	[trialTable reloadData];
    [percentTable reloadData];
}

@end
