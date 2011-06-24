/*
 *  DaVinciRenderWindow.h
 *  DaVinci
 *
 *  Created by Joël Spaltenstein on 3/17/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __DaVinciRenderWindow
#define __DaVinciRenderWindow

#include "vtkCocoaRenderWindow.h"

#ifdef __OBJC__
@class DaVinciGLView;
@class NSDictionary;
@class NSOpenGLPixelFormat;
@class NSOpenGLContext;
@class NSView;
#else
class DaVinciGLView;
class NSDictionary;
class NSOpenGLPixelFormat;
class NSOpenGLContext;
class NSView;
#endif

// handle rendering into two different contexts.

// we will have a second NSView that knows about this renderWindow.

// this other view will also keep an eye on the VRView, and if the VR view draws, it will setNeedsDispaly on itself.

// in it's draw rect, it will call a different call on the renderer which will set the new size, 


class DaVinciRenderWindow : public vtkCocoaRenderWindow
{
public:
    vtkTypeMacro(DaVinciRenderWindow,vtkCocoaRenderWindow);
    static DaVinciRenderWindow *New();
    void PrintSelf(ostream& os, vtkIndent indent);
        
//    virtual void *GetWindowId();
//    virtual void SetWindowId(void *);
//    virtual void *GetParentId();
//    virtual void SetParentId(void *nsview);
//    void *GetContextId();
//    void SetContextId(void *);
//    void *GetPixelFormat();
//    void SetPixelFormat(void *pixelFormat);
    
    void InitializeSharedOpenGLContext(NSOpenGLContext *);
    void RenderToDaVinciGLView(DaVinciGLView *, int[2]); // the DaVinciGLView's context must be shared with the DaVinciRenderWindow's context
    NSDictionary *GetCocoaDictionary();
    NSOpenGLPixelFormat *GetCocoaPixelFormat();
    NSOpenGLContext *GetCocoaOpenGLContext();
    NSView *GetCocoaView();
    
    virtual void Render();
    virtual int *GetSize();
    virtual void Frame();
    virtual void WaitForCompletion();
    
    
    virtual int SetPixelData(int x,int y,int x2,int y2,unsigned char *data,
                             int front);
    virtual int SetPixelData(int x,int y,int x2,int y2,
                             vtkUnsignedCharArray *data, int front);
    
    virtual int SetRGBAPixelData(int x,int y,int x2,int y2, float *data,
                                 int front, int blend=0);
    virtual int SetRGBAPixelData(int x,int y,int x2,int y2, vtkFloatArray *data,
                                 int front, int blend=0);
    virtual int SetRGBACharPixelData(int x, int y, int x2, int y2,
                                     unsigned char *data, int front,
                                     int blend=0);
    virtual int SetRGBACharPixelData(int x,int y,int x2,int y2,
                                     vtkUnsignedCharArray *data, int front,
                                     int blend=0);
    virtual int SetZbufferData( int x1, int y1, int x2, int y2, float *buffer );
    virtual int SetZbufferData( int x1, int y1, int x2, int y2,
                               vtkFloatArray *buffer );
    
    
    
    
protected:
    DaVinciRenderWindow();
    ~DaVinciRenderWindow() {}    
    
private:
    bool _renderToAlternateContext;
    int _alternateSize[2];
//    DaVinciGLView *_daVinciView;
};

#endif

