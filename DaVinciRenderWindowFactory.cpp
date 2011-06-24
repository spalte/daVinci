/*
 *  DaVinciRenderWindowFactory.cpp
 *  DaVinci
 *
 *  Created by Joël Spaltenstein on 3/17/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "DaVinciRenderWindowFactory.h"
#include "DaVinciRenderWindow.h"

//#define VTK_SOURCE_VERSION "VTK-5-6"

//VTK_FACTORY_INTERFACE_IMPLEMENT(DaVinciRenderWindowFactory);

VTK_CREATE_CREATE_FUNCTION(DaVinciRenderWindow);

vtkStandardNewMacro(DaVinciRenderWindowFactory);

void DaVinciRenderWindowFactory::PrintSelf(ostream& os, vtkIndent indent)
{
    os << indent << "DaVinci Render Window Object Factory" << endl;
}

DaVinciRenderWindowFactory::DaVinciRenderWindowFactory()
{
    cerr << "in constructor" << endl;
    this->RegisterOverride("vtkCocoaRenderWindow",
                           "DaVinciRenderWindow",
                           "DaVinci multiple context rendering",
                           1,
                           vtkObjectFactoryCreateDaVinciRenderWindow);
}

const char* DaVinciRenderWindowFactory::GetVTKSourceVersion()
{
    return "VTK-5-1";
}

const char* DaVinciRenderWindowFactory::GetDescription()
{
    return "DaVinci Render Window Object Factory";
}