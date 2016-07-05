//
//  LLSchedule.h
//
//  Created by John Maunsell on Sat Aug 31 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "LLScheduleController.h"

@interface LLSchedule : NSObject {

@protected
BOOL			abortFlag;
LLScheduleController	*controller;
unsigned long	count;
double			delayS;
BOOL			dropOutOK;
void 			(*function)(id, SEL, ...);
double			maximum;
double			minimum;
double			n;
id				object;
double			periodS;
double 			*pGrandN;
double 			*pGrandSum;
double 			*pGrandSumsq;
double			*pGrandMax;
double			*pGrandMin;
SEL				selector;
NSDate 			*startDate;
NSLock			*statLock;
double			statUpdates;
double			sum;
double			sumsq;
id				target;	
}

- (void)abort;
- (LLSchedule *)initWithSettings:(ScheduleSettings)settings;
- (void)run;
- (void)updateStats:(BOOL)mustUpdate;

@end


