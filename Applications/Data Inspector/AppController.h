//
//  AppController.h
//  Document Viewer
//
//  Created by John Maunsell on Sun Jun 16 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferenceController.h"

@interface AppController : NSObject {
    PreferenceController 	*preferenceController;
}

- (IBAction)showPreferencePanel:(id)sender;

@end
