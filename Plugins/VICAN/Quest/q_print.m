/****************** FUNCTION DESCRIPTION ********************

USAGE		
	q_print (file,cond,qc,threshold_estimate,fakeIt,actualThreshold);

ARGUMENTS	
	file - file pointer
	qc - ptr to condition for which data summary is to be printed.
	cond - an arbitrary number assigned by the user to refer to this 
			condition.
	threshold_estimate 

SUMMARY		
	Prints a data summary for condition to a file. Data summary consists of:
	- condition number
	- total trials presented
	- for each intensity for which at least one trial was presented:
		- number of trials
		- number of responses of each kind

RETURN VALUE
	Returns 0 if successful, -1 if not.

EXAMPLES
	#include <stdio.h>
	.
	.
	.
	for (cond=0; cond<nConds; cond++)
		q_print(stdout,qcs[cond],cond,threshold_estimate);

	-- Writes a data summary for each condition on standard output.

ERROR HANDLING & BOUNDARY CONDITIONS
	If file is NULL, output will be sent to stdout to ensure that the data are
not lost.

COMMENTS

REVISION HISTORY
	9/85		Version 1, A. B. Watson and K. Baldwin
	10/16/86	Version 2, A. Fitzhugh
	11/6/87	FW: receive cond and (QCondition *)qc
	8/31/91	dgp	updated, replacing Qright by responses[r]
				added actualThreshold
	3/6/94	dgp	assume q_error() will return INF when interval is unbounded
	8/15/94	ccc skip all fprintf messages if MATLAB is true.

*********************************************************/

#include	<stdio.h>
#include	"q_include.h"
void q_print(FILE *file,int cond,QCondition *qc,double threshold_estimate
	,int fakeIt,double actualThreshold)
{
#if !MATLAB
	int i,r;
	
	if (file==NULL) file=stdout;
	fprintf(file,"\nCondition %d, %ld trials. ",cond,(long)qc->trialsTotal);
	fprintf(file,"Estimated threshold is %4.3f +/-",threshold_estimate);
	fprintf(file," %4.3f",q_error(qc)/2.);
	if(fakeIt) fprintf(file," (Actually %.3f)",actualThreshold);
	fprintf(file,"\n");
	fprintf(file,"\nintensity trials");
	for (r=0; r<qc->nResponses; r++) fprintf(file," \"%d\"  ",r);
	for (r=0; r<qc->nResponses; r++) fprintf(file,"\"%d\"   ",r);
//	fprintf(file,"\n",r);
	fprintf(file,"\n");
	for (i=0; i<qc->nLevels; i++) if(qc->trials[i]>0) {
		fprintf(file,"%9.2f%6d",itov(qc,i),qc->trials[i]);
		for (r=0; r<qc->nResponses; r++)
			fprintf(file,"%6d",qc->responses[r][i]);
		for (r=0; r<qc->nResponses; r++)
			fprintf(file,"%5.0f%%",qc->responses[r][i]*100.0/qc->trials[i]);
		fprintf(file,"\n");
	}
#endif
}
