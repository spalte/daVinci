//
//  DaVinciGLView.h
//  DaVinci
//
//  Created by Joël Spaltenstein on 3/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// this is the view that will be drawn full screen in the daVinci display
@class vtkCocoaGLView;

#if defined(__cplusplus)
class DaVinciRenderWindow;
#else
typedef DaVinciRenderWindow void;
#endif

enum _DaVinciEye {
    DaVinciLeftEye = 0,
    DaVinciRightEye = 1,
};
typedef NSInteger DaVinciEye;

#define DaVinciGLViewTextureCount 7

@interface DaVinciGLView : NSView {
    vtkCocoaGLView *_mirroredView;
    DaVinciEye _eye;
    
    NSOpenGLPixelFormat *_pixelFormat;
    NSOpenGLContext *_openGLContext;
    DaVinciRenderWindow *_renderWindow;
    
    BOOL _forceBestRendering;
    BOOL _holdFlush;
}

- (id)initWithFrame:(NSRect)frame mirroredView:(vtkCocoaGLView *)mirroredView;

@property (nonatomic, readwrite, assign) BOOL forceBestRendering; // when this is true, all rendering with be done with best possible rendering
@property (nonatomic, readwrite, assign) DaVinciEye eye;

- (NSOpenGLContext *)openGLContext;
- (NSOpenGLPixelFormat *)pixelFormat;

- (NSImage *)screenImage;

@end
