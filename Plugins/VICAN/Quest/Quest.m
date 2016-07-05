/*
Quest.c
High-level user-callable routines to use the Quest structure and subroutines.
HISTORY:
8/31/91	dgp	wrote it.
4/23/92	dgp	changed !IsInf() to IsNan() in QuestQuantile. Added WeibullPResponse().
5/14/92	dgp	added QuestSd() and one-line descriptions.
12/8/92	dgp Fixed QuestSample() to actually return the value. Changed QuestPrintf 
declaration to return void.
*/
#include "Quest.h"
//#include <stdlib.h>

// Get best intensity for next trial
double QuestQuantile(Quest *q,int cond)
{
//	if (IsNan(q->quantileOrder)) {
	if (isnan(q->quantileOrder)) {
		q->quantileOrder = q_bestQuantileOrder(q->qConds[cond]);
	}
	return q_quantile(q->qConds[cond],q->quantileOrder);
}

// Save results of latest trial
void QuestUpdate(Quest *q,int cond,double intensity,int response)
{
	q_updateCond(q->qConds[cond],intensity,response);
}

// Optional simulation of observer
int QuestSimulateObserver(Quest *q,int cond,double intensity)
{
	return q_getResponse(q->qConds[cond],q->actualThreshold[cond],intensity);
}

// Choose a threshold as a random sample from the current probability distribution.
double QuestGetSample(Quest *q,int cond)
{
	return q_getSample(q->qConds[cond]);
}

// Get best estimate of threshold
double QuestMean(Quest *q,int cond)
{
	return q_mean(q->qConds[cond]);
}

// Get associated standard deviation of the threshold estimate
double QuestSd(Quest *q,int cond)
{
	return sqrt(q_variance(q->qConds[cond]));
}

// A very crude trial-by-trial typewriter graph of the sequential threshold estimation
void QuestPlot(Quest *q,int cond,double intensity,int response)
{
	q_plot(q->qConds[cond],cond,intensity,response,q->fakeIt,q->actualThreshold[cond]);
}

void QuestPrint(FILE *file,Quest *q,int cond)
{
	q_print(file,cond,q->qConds[cond],q->thresholdEstimate[cond]
		,q->fakeIt,q->actualThreshold[cond]);
}

// QuestPResponse returns the probability of a given response at a given intensity,
// using the specifications within the Quest structure.
double QuestPResponse(Quest *q,int response,double intensity)
{
	return (*q->function)(response,intensity,q->beta,q->gamma,q->delta,q->epsilon);
}

// The following PResponseFunction is for use as an argument to QuestOpen().
double WeibullPResponse(int response,double intensity
	,double beta,double gamma,double delta,double epsilon)
{
	return q_Weibull(response,intensity,beta,gamma,delta,epsilon);
}

