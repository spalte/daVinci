/*
 *  DaVinciRenderWindow.cpp
 *  DaVinci
 *
 *  Created by Joël Spaltenstein on 3/17/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "DaVinciGLView.h"

#include "DaVinciRenderWindow.h"
#include "vtkCollection.h"
#include "vtkRenderer.h"
#include "vtkRendererCollection.h"
#include "vtkCamera.h"
#include "vtkObjectFactory.h"

vtkStandardNewMacro(DaVinciRenderWindow);

void DaVinciRenderWindow::PrintSelf(ostream& os, vtkIndent indent)
{
    os << indent << "DaVinci Render Window" << endl;
    this->Superclass::PrintSelf(os, indent.GetNextIndent());
}


DaVinciRenderWindow::DaVinciRenderWindow()
{
    _renderToAlternateContext = false;
    _alternateSize[0] = 0.0;
    _alternateSize[1] = 0.0;
    NSLog(@"OMG");
}

NSDictionary *DaVinciRenderWindow::GetCocoaDictionary()
{
    return (id)GetCocoaManager();
}

NSOpenGLPixelFormat *DaVinciRenderWindow::GetCocoaPixelFormat()
{
    return [(NSDictionary *)GetCocoaManager() objectForKey:@"PixelFormat"];
}

NSOpenGLContext *DaVinciRenderWindow::GetCocoaOpenGLContext()
{
    return [(NSDictionary *)GetCocoaManager() objectForKey:@"ContextId"];
}

NSView *DaVinciRenderWindow::GetCocoaView()
{
    return [(NSDictionary *)GetCocoaManager() objectForKey:@"DisplayId"];
}

void DaVinciRenderWindow::InitializeSharedOpenGLContext(NSOpenGLContext *context)
{
    NSMutableDictionary *cocoaManager;
    NSDictionary *oldCocoaManager;
    
    cocoaManager = (NSMutableDictionary *)GetCocoaManager();
    
    oldCocoaManager = [cocoaManager copy];
    [cocoaManager removeAllObjects];
    [cocoaManager setObject:context forKey:@"ContextId"];
        
    _renderToAlternateContext = true;
    
    this->MakeCurrent();
    this->OpenGLInit();
    
    [cocoaManager setDictionary:oldCocoaManager];
    
    _renderToAlternateContext = false;
    
    [oldCocoaManager release];
}

void DaVinciRenderWindow::RenderToDaVinciGLView(DaVinciGLView *daVinciView, int size[2])
{
    NSMutableDictionary *cocoaManager;
    NSDictionary *oldCocoaManager;
    int *tmpSize;
    int previousSize[2];
    
    tmpSize = GetSize();
    previousSize[0] = tmpSize[0];
    previousSize[1] = tmpSize[1];
    
    cocoaManager = (NSMutableDictionary *)GetCocoaManager();
    
    oldCocoaManager = [cocoaManager copy];
    [cocoaManager removeAllObjects];
    [cocoaManager setObject:daVinciView forKey:@"DisplayId"];
    [cocoaManager setObject:[daVinciView openGLContext] forKey:@"ContextId"];
    [cocoaManager setObject:[daVinciView pixelFormat] forKey:@"PixelFormat"];
    
    _renderToAlternateContext = true;
    _alternateSize[0] = size[0];
    _alternateSize[1] = size[1];
    
    this->Modified();
    GetSize(); // to make sure the size variables are really set...
    
    this->MakeCurrent();
    
    this->Render();
    
    [cocoaManager setDictionary:oldCocoaManager];

    _renderToAlternateContext = false;
    _alternateSize[0] = 0.0;
    _alternateSize[1] = 0.0;
    this->Size[0] = previousSize[0];
    this->Size[1] = previousSize[1];
    
    this->MakeCurrent();
    
    this->Modified();
    GetSize(); // to make sure the size variables are really set...

    [oldCocoaManager release];
}

int *DaVinciRenderWindow::GetSize()
{
    if (_renderToAlternateContext) {
        this->Size[0] = _alternateSize[0];
        this->Size[1] = _alternateSize[1];
        return _alternateSize;
    } else {
        return this->Superclass::GetSize();
    }
}

void DaVinciRenderWindow::Render()
{
    if (!_renderToAlternateContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DaVinciVTKCocoaViewWillDrawNotification" object:GetCocoaView()];
        this->Superclass::Render();
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DaVinciVTKCocoaViewDidDrawNotification" object:GetCocoaView()];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DaVinciVTKCocoaViewPostDidDrawNotification" object:GetCocoaView()];
    } else {
        this->Superclass::Render();
    }
}

void DaVinciRenderWindow::Frame()
{
    if (!_renderToAlternateContext) {
        this->Superclass::Frame();
    }
}

void DaVinciRenderWindow::WaitForCompletion()
{
    assert(0);
}

int DaVinciRenderWindow::SetPixelData(int x,int y,int x2,int y2,unsigned char *data,
                         int front)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetPixelData( x, y, x2, y2,data, front);
    } else {
        return VTK_OK;
    }
}

int DaVinciRenderWindow::SetPixelData(int x,int y,int x2,int y2,
                         vtkUnsignedCharArray *data, int front)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetPixelData( x, y, x2, y2,data,  front);
    } else {
        return VTK_OK;
    }
}

int DaVinciRenderWindow::SetRGBAPixelData(int x,int y,int x2,int y2, float *data,
                             int front, int blend)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetRGBAPixelData( x, y, x2, y2,  data,  front,  blend);
    } else {
        return VTK_OK;
    }
}

int DaVinciRenderWindow::SetRGBAPixelData(int x,int y,int x2,int y2, vtkFloatArray *data,
                             int front, int blend)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetRGBAPixelData( x, y, x2, y2,  data, front,  blend);
    } else {
        return VTK_OK;
    }
}

int DaVinciRenderWindow::SetRGBACharPixelData(int x, int y, int x2, int y2,
                                 unsigned char *data, int front,
                                 int blend)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetRGBACharPixelData( x,  y,  x2,  y2, data,  front, blend);
    } else {
        return VTK_OK;
    }
}


int DaVinciRenderWindow::SetRGBACharPixelData(int x,int y,int x2,int y2,
                                 vtkUnsignedCharArray *data, int front,
                                 int blend)
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetRGBACharPixelData( x, y, x2, y2,data,  front, blend);
    } else {
        return VTK_OK;
    }
}


int DaVinciRenderWindow::SetZbufferData( int x1, int y1, int x2, int y2, float *buffer )
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetZbufferData(  x1,  y1,  x2,  y2, buffer );
    } else {
        return VTK_OK;
    }
}


int DaVinciRenderWindow::SetZbufferData( int x1, int y1, int x2, int y2,
                           vtkFloatArray *buffer )
{
    if (!_renderToAlternateContext) {
        return this->Superclass::SetZbufferData(  x1,  y1,  x2,  y2, buffer);
    } else {
        return VTK_OK;
    }
}









