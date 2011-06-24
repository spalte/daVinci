/*
 *  DaVinciRenderWindowFactory.h
 *  DaVinci
 *
 *  Created by Joël Spaltenstein on 3/17/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __DaVinciRenderWindowFactory
#define __DaVinciRenderWindowFactory

#include "vtkObjectFactory.h"

class DaVinciRenderWindowFactory : public vtkObjectFactory
{
public: 
    // Methods from vtkObject
    vtkTypeMacro(DaVinciRenderWindowFactory,vtkObjectFactory);
    static DaVinciRenderWindowFactory *New();
    void PrintSelf(ostream& os, vtkIndent indent);
    virtual const char* GetVTKSourceVersion();
    virtual const char* GetDescription();
    
protected:
    DaVinciRenderWindowFactory();
    ~DaVinciRenderWindowFactory() { }    
private:
    DaVinciRenderWindowFactory(const DaVinciRenderWindowFactory&);  // Not implemented.
    void operator=(const DaVinciRenderWindowFactory&);  // Not implemented.
};


#endif

