//
//  DaVinciPlugin.m
//  DaVinci
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DaVinciPlugin.h"
#import "DaVinciGLView.h"
#import "vtkObjectFactory.h"
#import "DaVinciRenderWindowFactory.h"
#import "vtkObject.h"
#import "vtkCocoaRenderWindow.h"
#import "DaVinciRenderWindow.h"
#import "vtkCocoaGLView.h"
#import <objc/runtime.h>

#include <IOKit/graphics/IOGraphicsLib.h>

static DaVinciPlugin *_sharedDaVinciPlugin = nil;

static const NSString *_DaVinciDisplayProductName = @"This Would Be Cool";

const NSString *DaVinciVTKCocoaViewWillDrawNotification = @"DaVinciVTKCocoaViewWillDrawNotification";
const NSString *DaVinciVTKCocoaViewDidDrawNotification = @"DaVinciVTKCocoaViewDidDrawNotification";
const NSString *DaVinciVTKCocoaViewPostDidDrawNotification = @"DaVinciVTKCocoaViewPostDidDrawNotification";

@interface DaVinciPlugin ()

+ (DaVinciPlugin *)sharedDaVinciPlugin;
- (BOOL)_takeoverDaVinciScreens;
- (void)_windowDidBecomeMainNotification:(NSNotification *)notification;
- (vtkCocoaGLView *)_findVTKCocoaGLViewInView:(NSView *)view;
- (void)setMirroredView:(vtkCocoaGLView *)mirroredView;
- (void)_setDaVinciFriendlyPreferences;

@end


@implementation DaVinciPlugin

@synthesize daVinciGLViewLeft = _daVinciGLViewLeft;
@synthesize daVinciGLViewRight = _daVinciGLViewRight;

+ (DaVinciPlugin *)sharedDaVinciPlugin
{
    return _sharedDaVinciPlugin;
}

- (void)initPlugin
{ 
    NSLog(@"loaded DaVinciPlugin");
    _sharedDaVinciPlugin = [self retain];
    vtkObjectFactory::RegisterFactory(DaVinciRenderWindowFactory::New());
    [self _takeoverDaVinciScreens];
    [self _setDaVinciFriendlyPreferences];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidBecomeMainNotification:) name:NSWindowDidBecomeMainNotification object:nil];
}

+ (NSScreen *)daVinciScreenLeft
{
//    if ([[NSScreen screens] count] < 3) {
//        return nil;
//    }
    
    return [[NSScreen screens] objectAtIndex:1];
}

+ (NSScreen *)daVinciScreenRight
{
//    if ([[NSScreen screens] count] < 3) {
//        return nil;
//    }
    
    return [[NSScreen screens] objectAtIndex:2];
}
//{
//    NSInteger i = 0;
//    
//    NSScreen *screen;
//    NSDictionary *deviceDescritpion;
//    NSNumber *screenNumber;
//    CGDirectDisplayID directDisplayID;
//    io_service_t displayService;
//    NSDictionary *displayInfoDictionary;
//    NSDictionary *displayProductNamesDictionary;
//    NSString *displayProductName;
//    for (screen in [NSScreen screens]) {
//        deviceDescritpion = [screen deviceDescription];
//        screenNumber = [deviceDescritpion objectForKey:@"NSScreenNumber"];
//        directDisplayID = [screenNumber unsignedIntValue];
//        displayService = CGDisplayIOServicePort(directDisplayID);
//        displayInfoDictionary = (NSDictionary*)IODisplayCreateInfoDictionary(displayService, kIODisplayOnlyPreferredName);
//        displayProductNamesDictionary = [displayInfoDictionary objectForKey:(NSString *)CFSTR(kDisplayProductName)];
//        displayProductName = [displayProductNamesDictionary objectForKey:[[displayProductNamesDictionary allKeys] objectAtIndex:0]];
//        //        if ([displayProductName isEqualToString:_DaVinciDisplayProductName]) {
//        //        if ([displayProductName isEqualToString:@"DELL 2208WFP"] == NO) {
//        if (i == 1) {
//            return screen;
//        }
//        i++;
//    }
//    
//    return nil;
//}

- (BOOL)_takeoverDaVinciScreens
{
    NSScreen *daVinciScreenLeft;
    NSScreen *daVinciScreenRight;
    NSRect daVinciDisplayRect;
    NSRect viewRect;
    NSOpenGLView *fullScreenView;
    
    daVinciScreenLeft = [DaVinciPlugin daVinciScreenLeft];
    daVinciScreenRight = [DaVinciPlugin daVinciScreenRight];
    
//    if (daVinciScreenLeft == nil || daVinciScreenRight == nil) {
//        return NO;
//    }
    
    // do the left
    daVinciDisplayRect = [daVinciScreenLeft frame];
	_daVinciWindowLeft = [[NSWindow alloc] initWithContentRect:daVinciDisplayRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    [_daVinciWindowLeft setLevel:NSMainMenuWindowLevel+1];
	[_daVinciWindowLeft setOpaque:YES];

	viewRect = NSMakeRect(0.0, 0.0, daVinciDisplayRect.size.width, daVinciDisplayRect.size.height);
	fullScreenView = [[[NSOpenGLView alloc] initWithFrame:viewRect pixelFormat:[NSOpenGLView defaultPixelFormat]] autorelease];
	[_daVinciWindowLeft setContentView:fullScreenView];
    
    [_daVinciWindowLeft orderFront:self];
    
    // do the right
    daVinciDisplayRect = [daVinciScreenRight frame];
	_daVinciWindowRight = [[NSWindow alloc] initWithContentRect:daVinciDisplayRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    [_daVinciWindowRight setLevel:NSMainMenuWindowLevel+1];
	[_daVinciWindowRight setOpaque:YES];
    
	viewRect = NSMakeRect(0.0, 0.0, daVinciDisplayRect.size.width, daVinciDisplayRect.size.height);
	fullScreenView = [[[NSOpenGLView alloc] initWithFrame:viewRect pixelFormat:[NSOpenGLView defaultPixelFormat]] autorelease];
	[_daVinciWindowRight setContentView:fullScreenView];
    
    [_daVinciWindowRight orderFront:self];
    
    
}

- (void)_windowDidBecomeMainNotification:(NSNotification *)notification
{
    NSWindow *window;
    vtkCocoaGLView *vtkView;

    window = [notification object];
    vtkView = [self _findVTKCocoaGLViewInView:[window contentView]];
    
    [self setMirroredView:vtkView];
}

- (vtkCocoaGLView *)_findVTKCocoaGLViewInView:(NSView *)view
{
    NSView *subView;
    vtkCocoaGLView *vtkView;
    
    if ([view isKindOfClass:[vtkCocoaGLView class]]) {
        return (vtkCocoaGLView *)view;
    } else {
        for (subView in [view subviews]) {
            vtkView = [self _findVTKCocoaGLViewInView:subView];
            if (vtkView) {
                return vtkView;
            }
        }
    }
    
    return nil;
}

- (void)_setDaVinciFriendlyPreferences
{
    NSUserDefaults *standardUserDefaults;
    standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    [standardUserDefaults registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"daVinciPluginHasBeenLoaded"]];
    
    if ([standardUserDefaults boolForKey:@"daVinciPluginHasBeenLoaded"] == NO) {
        [standardUserDefaults setInteger:4 forKey:@"superSampling"]; // this cooresponds to hight quality rendering for "Best" renderings
        [standardUserDefaults setBool:NO forKey:@"autorotate3D"];
        [standardUserDefaults setInteger:2 forKey:@"VRDefaultViewSize"]; // this cooresponds to 512x512 rendering in the main VR view
        [standardUserDefaults setInteger:2 forKey:@"ReserveScreenForDB"]; // this cooresponds to open the viewers in the same screen as the DB window
    }
    [standardUserDefaults setBool:YES forKey:@"daVinciPluginHasBeenLoaded"];
}

- (void)setMirroredView:(vtkCocoaGLView *)mirroredView
{
    NSRect daVinciDisplayRect;
    NSRect viewRect;
    NSView *newView;
    DaVinciRenderWindow *renderWindow;
    if (mirroredView != _mirroredView) {
        NSLog(@"setting the mirrored view");
        [_mirroredView release];
        _mirroredView = [mirroredView retain];
        
        // do the left
        daVinciDisplayRect = [[DaVinciPlugin daVinciScreenLeft] frame];
        viewRect = NSMakeRect(0.0, 0.0, daVinciDisplayRect.size.width, daVinciDisplayRect.size.height);

        if (_mirroredView) {
            newView = [[[DaVinciGLView alloc] initWithFrame:viewRect mirroredView:_mirroredView] autorelease];
            [(DaVinciGLView *)newView setEye:DaVinciLeftEye];
            [_daVinciGLViewLeft release];
            _daVinciGLViewLeft = [newView retain];
        } else {
            newView = [[[NSOpenGLView alloc] initWithFrame:viewRect pixelFormat:[NSOpenGLView defaultPixelFormat]] autorelease];
            [_daVinciGLViewLeft release];
            _daVinciGLViewLeft = nil;
        }
        
        [_daVinciWindowLeft setContentView:newView];
        
        // do the right
        daVinciDisplayRect = [[DaVinciPlugin daVinciScreenLeft] frame];
        viewRect = NSMakeRect(0.0, 0.0, daVinciDisplayRect.size.width, daVinciDisplayRect.size.height);
        
        if (_mirroredView) {
            newView = [[[DaVinciGLView alloc] initWithFrame:viewRect mirroredView:_mirroredView] autorelease];
            [(DaVinciGLView *)newView setEye:DaVinciRightEye];
            [_daVinciGLViewRight release];
            _daVinciGLViewRight = [newView retain];
        } else {
            newView = [[[NSOpenGLView alloc] initWithFrame:viewRect pixelFormat:[NSOpenGLView defaultPixelFormat]] autorelease];
            [_daVinciGLViewRight release];
            _daVinciGLViewRight = nil;
        }
        
        [_daVinciWindowRight setContentView:newView];        
    }
}


@end

                
                
                
                













