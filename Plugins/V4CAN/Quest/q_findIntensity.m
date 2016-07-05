/*********************** FUNCTION DESCRIPTION *************************

USAGE

	error=q_findIntensity(p,q->function,response,&intensity,q->beta,q->gamma,q->delta,q->epsilon);

SUMMARY

	q_findIntensity() sets the *intensity argument so that the psychometric
	function will take on value p, given the other arguments.
	The returned value of q_findIntensity is the difference between the
	found and requested probabilities.

EXAMPLES

	Several people have been asking how to set epsilon in q_Weibull to 
	attain a particular threshold criterion. In that routine intensity and
	epsilon are interchangeable; the routine only uses their sum. So, to
	set epsilon so that the threshold criterion will be p, do this:
	
	q_findIntensity(p,q_Weibull,response,&q->epsilon,q->beta,q->gamma,q->delta,0);
	
RETURN VALUE

ERROR HANDLING & LIMITATIONS

HISTORY
	2/20/94	DGP wrote it
*****************************************************************************/
#include "q_include.h"
static double errorFunction(double intensity);	/* just for internal use */
static PResponseFunction qFunction;
//static double qIntensity;
static double qP,qBeta,qGamma,qDelta,qEpsilon;
static int qResponse;

double q_findIntensity(double p,PResponseFunction function
	,int response,double *intensityPtr,double beta,double gamma,double delta
	,double epsilon)
{
	double tol;
	
	qFunction=function;
	qP=p;
	qResponse=response;
	qBeta=beta;
	qGamma=gamma;
	qDelta=delta;
	qEpsilon=epsilon;
	tol=1e-8;
	q_brent(-1.0,0.0,1.0,errorFunction,tol,intensityPtr);
	return (*qFunction)(response,*intensityPtr,beta,gamma,delta,epsilon)-p;
}

static double errorFunction(double intensity)	/* just for internal use */
{
	double p;

	p=(*qFunction)(qResponse,intensity,qBeta,qGamma,qDelta,qEpsilon);
	p-=qP;
	return p*p;
}

