/*
FTStimuli.h
*/

@interface FTStimuli : NSObject {

	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
}

- (void)drawFixSpot;
- (void)erase;
- (LLFixTarget *)fixSpot;

@end
