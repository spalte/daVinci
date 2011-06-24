//
//  DaVinciPlugin.h
//  DaVinci
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "vtkCocoaGLView.h"

extern const NSString *DaVinciVTKCocoaViewWillDrawNotification;
extern const NSString *DaVinciVTKCocoaViewDidDrawNotification;
extern const NSString *DaVinciVTKCocoaViewPostDidDrawNotification;

@class DaVinciGLView;

@interface DaVinciPlugin : PluginFilter {
    NSWindow *_daVinciWindowLeft;
    DaVinciGLView *_daVinciGLViewLeft;
    NSWindow *_daVinciWindowRight;
    DaVinciGLView *_daVinciGLViewRight;
        
    vtkCocoaGLView *_mirroredView;
}

@property (nonatomic, readonly, retain) DaVinciGLView *daVinciGLViewLeft;
@property (nonatomic, readonly, retain) DaVinciGLView *daVinciGLViewRight;

// pluginFiltermethods
- (void)initPlugin;


// DaVinci plugin methods
+ (NSScreen *)daVinciScreenLeft;
+ (NSScreen *)daVinciScreenRight;

@end
    