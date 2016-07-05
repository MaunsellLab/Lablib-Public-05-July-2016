/*
 *  Lablib.h
 *  Lablib
 *
 *  Created by John Maunsell on Wed Jan 29 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */
/*!
  @header Lablib
  Lablib provide a collection of Objective C classes supporting real-time 
  data collection and display under OS X.
*/

#define kPI						(atan(1) * 4)
#define kDegPerRadian			(180.0 / kPI)

#define CHECK(LINE, EXPECTED) {\
	int rc = LINE;\
	if (rc != EXPECTED) {\
		fprintf(stderr, "%s line %d -- '%s': expected %d, got %d\n",\
			__FILE__, __LINE__, #LINE, EXPECTED, rc);\
		exit(1);\
	}\
}

#import <Lablib/LLBar.h>
#import <Lablib/LLBinocCalibrator.h>
#import <Lablib/LLBinomDist.h>
#import <Lablib/LLControlPanel.h>
#import <Lablib/LLDataDevice.h>
#import <Lablib/LLDataDoc.h>
#import <Lablib/LLDataEventDef.h>
#import <Lablib/LLDataReader.h>
#import <Lablib/LLDataFileReader.h>
#import <Lablib/LLDataUtil.h>
#import <Lablib/LLDefaultAboutBox.h>
//#import <Lablib/LLDisplayEDID.h>
#import <Lablib/LLDisplays.h>
#import <Lablib/LLDisplayPhysical.h>
#import <Lablib/LLDisplayUtilities.h>
#import <Lablib/LLDistribution.h>
#import <Lablib/LLDrawable.h>
#import <Lablib/LLEOTHistoryView.h>
#import <Lablib/LLEOTView.h>
#import <Lablib/LLEyeCalibrator.h>
#import <Lablib/LLEyeWindow.h>
#import <Lablib/LLEyeXYView.h>
#import <Lablib/LLFactorToOctaveStepTransformer.h>
#import <Lablib/LLFilterExp.h>
#import <Lablib/LLFixTarget.h>
#import <Lablib/LLHistView.h>
#import <Lablib/LLIODevice.h>
#import <Lablib/LLIODeviceController.h>
#import <Lablib/LLDataDeviceController.h>
#import <Lablib/LLGabor.h>
#import <Lablib/LLHeatMapView.h>
#import <Lablib/LLIntervalMonitor.h>
#import <Lablib/LLLaserCalibrator.h>
#import <Lablib/LLMathUtil.h>
#import <Lablib/LLMonitorController.h>
#import <Lablib/LLMouseDataDevice.h>
#import <Lablib/LLMultiplierTransformer.h>
#import <Lablib/LLNoise.h>
#import <Lablib/LLNormDist.h>
#import <Lablib/LLNumberMatchTransformer.h>
#import <Lablib/LLNumberNonMatchTransformer.h>
#import <Lablib/LLOldGabor.h>
#import <Lablib/LLParameterController.h>
#import <Lablib/LLPlaid.h>
#import <Lablib/LLPlotColors.h>
#import <Lablib/LLPlotView.h>
#import <Lablib/LLPluginController.h>
#import <Lablib/LLPointDist.h>
#import <Lablib/LLProgressIndicator.h>
#import <Lablib/LLPulseTrain.h>
#import <Lablib/LLPulseTrainDevice.h>
#import <Lablib/LLRandomDots.h>
#import <Lablib/LLScheduleController.h>
#import <Lablib/LLScrollZoomWindow.h>
#import <Lablib/LLSettingsController.h>
#import <Lablib/LLSounds.h>
#import <Lablib/LLStandardDataEvents.h>
#import <Lablib/LLStateSystem.h>
#import <Lablib/LLStatValues.h>
#import <Lablib/LLStimTrainDevice.h>
#import <Lablib/LLStimulusTrain.h>
#import <Lablib/LLStimWindow.h>
#import <Lablib/LLSVDSolver.h>
#import <Lablib/LLSynthDataDevice.h>
#import <Lablib/LLSystemUtil.h>
#import <Lablib/LLTaskMode.h>
#import <Lablib/LLTaskModeTransformer.h>
#import <Lablib/LLTaskPlugIn.h>
#import <Lablib/LLTaskStatus.h>
#import <Lablib/LLTaskStatusImageTransformer.h>
#import <Lablib/LLTaskStatusTitleTransformer.h>
#import <Lablib/LLTaskStatusTransformer.h>
#import <Lablib/LLTextUtil.h>
#import <Lablib/LLTrialBlock.h>
#import <Lablib/LLUserDefaults.h>
#import <Lablib/LLViewScale.h>
#import <Lablib/LLVisualStimulus.h>
#import <Lablib/LLXTView.h>
