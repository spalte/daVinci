//
//  DaVinciGLView.m
//  DaVinci
//
//  Created by Joël Spaltenstein on 3/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DaVinciGLView.h"
#import "DaVinciPlugin.h"
#import "DaVinciRenderWindow.h"

#import "vtkCamera.h"
#import "vtkRenderer.h"
#import "vtkRendererCollection.h"
#import "vtkHomogeneousTransform.h"
#import "vtkTransform.h"
#import "vtkVolumeMapper.h"
#import "vtkFixedPointVolumeRayCastMapper.h"
#import "OsiriXFixedPointVolumeRayCastMapper.h"
#import "vtkActorCollection.h"
#import "vtkRendererCollection.h"
#import "vtkPropCollection.h"

extern int dontRenderVolumeRenderingOsiriX;	// See OsiriXFixedPointVolumeRayCastMapper.cxx

typedef double daVinciImageQuality; // 1 is best quality, 0 is poor quality

@interface DaVinciGLView ()

- (void)_VTKCocoaViewWillDrawNotification:(NSNotification *)notification;
- (void)_VTKCocoaViewDidDrawNotification:(NSNotification *)notification;
- (void)_VTKCocoaViewPostDidDrawNotification:(NSNotification *)notification;

- (BOOL)_snapshotToPath:(NSString *)path;

- (daVinciImageQuality)_imageQualityFromVTKVolumeMapper:(vtkFixedPointVolumeRayCastMapper *)mapper;

- (double)_sampleSpacingForImageQuality:(daVinciImageQuality)imageQuality;

@end


@implementation DaVinciGLView

@synthesize forceBestRendering = _forceBestRendering;
@synthesize eye = _eye;

- (id)initWithFrame:(NSRect)frame mirroredView:(vtkCocoaGLView *)mirroredView
{
    if ( (self = [super initWithFrame:frame]) ) {
        _mirroredView = [mirroredView retain];
        
        _renderWindow = static_cast<DaVinciRenderWindow *>([_mirroredView getVTKRenderWindow]);
        _pixelFormat = [_renderWindow->GetCocoaPixelFormat() retain];
        _openGLContext = [[NSOpenGLContext alloc] initWithFormat:_pixelFormat shareContext:_renderWindow->GetCocoaOpenGLContext()];
        [_openGLContext setView:self];
        _renderWindow->InitializeSharedOpenGLContext(_openGLContext);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_VTKCocoaViewWillDrawNotification:) name:DaVinciVTKCocoaViewWillDrawNotification object:_mirroredView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_VTKCocoaViewDidDrawNotification:) name:DaVinciVTKCocoaViewDidDrawNotification object:_mirroredView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_VTKCocoaViewPostDidDrawNotification:) name:DaVinciVTKCocoaViewPostDidDrawNotification object:_mirroredView];
    }
    return self;
}

- (void)dealloc
{
    CGLContextObj cgl_ctx;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_mirroredView release];
    _mirroredView = nil;
    
    [[self openGLContext] makeCurrentContext];
    cgl_ctx = (CGLContextObj)[[NSOpenGLContext currentContext] CGLContextObj];
        
    [_pixelFormat release];
    _pixelFormat = nil;
    [_openGLContext release];
    _openGLContext = nil;
    
    [super dealloc];
}

- (void)lockFocus
{
	[super lockFocus];
	if ([[self openGLContext] view] != self) {
		[[self openGLContext] setView:self];
    }
}

- (NSOpenGLContext *)openGLContext
{
    return _openGLContext;
}

- (NSOpenGLPixelFormat *)pixelFormat
{
    return _pixelFormat;
}

- (NSImage *)screenImage
{
    NSBitmapImageRep *imageRep;
    NSImage *image;
    NSImage *flippedImage;
    NSUInteger width;
    NSUInteger height;
    CGLContextObj cgl_ctx;

    [[self openGLContext] makeCurrentContext];
    cgl_ctx = (CGLContextObj)[[NSOpenGLContext currentContext] CGLContextObj];

	if ([[self openGLContext] view] != self) {
		[[self openGLContext] setView:self];
    }
    
    width = NSWidth([self frame]);
    height = NSHeight([self frame]);
    
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4
                                                         hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace
                                                     bitmapFormat:NSAlphaNonpremultipliedBitmapFormat | NSAlphaFirstBitmapFormat bytesPerRow:width * 4 bitsPerPixel:32];
    
    glReadBuffer(GL_FRONT);
    glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, [imageRep bitmapData]);
    
    image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    [imageRep release];
    
    flippedImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [flippedImage lockFocusFlipped:YES];
    [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
    [flippedImage unlockFocus];
    [image release];
    
    static NSInteger imageNumber = 1;
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Users/spalte/Documents/imageDump/image %d.tiff", imageNumber]];
    [[flippedImage TIFFRepresentation] writeToURL:fileURL atomically:NO];
    imageNumber++;
    
    return [flippedImage autorelease];
}

- (void)drawRect:(NSRect)dirtyRect
{
    vtkRenderer *renderer;
    vtkRenderer *secondRenderer;
    vtkCamera *camera;
    GLint uniformLocation;
    int size[2];
    int i;
    double savedShear[3];
    double savedPosition[3];
    double savedViewingAngle;
    double shear[3];
    double directionOfProjection[3];
    double newCameraPosition[3];
    double newDistance;
    double newClippingRange[2];
    double distance;
    double newViewAngle;
    double aspect;
    double tmp;
    double savedClippingRange[2];
    double newFocalPoint[3];
    double savedFocalPoint[3];
    int savedParallelProjection;
    double width;
    vtkHomogeneousTransform *savedUserTransform; 
    vtkTransform *scaleTransform;
    vtkAbstractVolumeMapper *volumeMapper;
    vtkFixedPointVolumeRayCastMapper *rayCastMapper;
    vtkActorCollection *initialActors;
    vtkActorCollection *savedActors;
    vtkPropCollection *propCollection;
    vtkPropCollection *savedPropCollection;
    vtkProp *prop;
    vtkRendererCollection *rendererCollection;
    vtkActor *actor;

    CGLContextObj cgl_ctx;
    
    if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
    
    [[self openGLContext] makeCurrentContext];
    cgl_ctx = (CGLContextObj)[[NSOpenGLContext currentContext] CGLContextObj];    	
    
    rendererCollection = _renderWindow->GetRenderers();
    rendererCollection->InitTraversal();
    renderer = rendererCollection->GetNextItem();
    secondRenderer = rendererCollection->GetNextItem();
    
    vtkVolumeCollection *volumeCollection;
    volumeCollection = renderer->GetVolumes();
    
    vtkVolume *volume;
    volumeCollection->InitTraversal();
    volume = volumeCollection->GetNextVolume();
    volumeMapper = volume->GetMapper();
    rayCastMapper = vtkFixedPointVolumeRayCastMapper::SafeDownCast(volumeMapper);
    if (rayCastMapper == NULL) { // this would be bad
        return;
    }
    
//    propCollection = renderer->GetProps();
//    savedPropCollection = vtkPropCollection::New();
//    
//    propCollection->InitTraversal();
//    while ( (prop = propCollection->GetNextProp()) ) {
//        savedPropCollection->AddItem(prop);
//    }
//    
//    savedPropCollection->InitTraversal();
//    while ( (prop = savedPropCollection->GetNextProp()) ) {
//        if (prop != volume) {
//            renderer->RemoveProp(prop);
//        } 
//    }
    
//    initialActors = secondRenderer->GetActors();
//    savedActors = vtkActorCollection::New();
//    initialActors->InitTraversal();
//    while ( (actor = initialActors->GetNextActor()) ) {
//        savedActors->AddItem(actor);
//    }
//    
//    savedActors->InitTraversal();
//    while ( (actor = savedActors->GetNextActor()) ) {
//        secondRenderer->RemoveActor(actor);
//    }
    
//    renderer->GetActors()
    // get all the actors, retain them, and stuff them in an NSArray for NSValues, we might be able to use 
            
//    rayCastMapper->SetAutoAdjustSampleDistances(0);
//    rayCastMapper->SetImageSampleDistance(1);
//    rayCastMapper->SetSampleDistance([self _sampleSpacingForImageQuality:imageQuality]);
        
    camera = renderer->GetActiveCamera();
    shear[1] = 0.0;
    shear[2] = 1.0;
    
    camera->GetViewShear(savedShear);
    camera->GetPosition(savedPosition);
    savedViewingAngle = camera->GetViewAngle();
    camera->GetFocalPoint(savedFocalPoint);
    savedParallelProjection = camera->GetParallelProjection();
    savedUserTransform = camera->GetUserTransform();
    if(savedUserTransform) {
        savedUserTransform->Register(NULL);
    }
    
    camera->GetDirectionOfProjection(directionOfProjection);
    distance = camera->GetDistance();
    
    aspect = [self bounds].size.width / [self bounds].size.height;
    distance = camera->GetDistance();
    camera->GetClippingRange(savedClippingRange);
    camera->GetDirectionOfProjection(directionOfProjection);
    
    if (savedParallelProjection) {
        width = (camera->GetParallelScale()*aspect) / 2.0;
    } else {
        tmp = tan(savedViewingAngle*M_PI/360.0);
        
        if (camera->GetUseHorizontalViewAngle()) {
            width = distance*tmp;
        } else {
            width = distance*tmp*aspect;
        }
    }
    
    camera->SetParallelProjection(0);

    {
        newDistance = (width / tan(18*M_PI/180.0));
        
        newFocalPoint[0] = savedFocalPoint[0] - directionOfProjection[0]*(newDistance * 0.12);
        newFocalPoint[1] = savedFocalPoint[1] - directionOfProjection[1]*(newDistance * 0.12);
        newFocalPoint[2] = savedFocalPoint[2] - directionOfProjection[2]*(newDistance * 0.12);
        camera->SetFocalPoint(newFocalPoint);
        
        newCameraPosition[0] = savedFocalPoint[0] - directionOfProjection[0]*(newDistance * 1.12);
        newCameraPosition[1] = savedFocalPoint[1] - directionOfProjection[1]*(newDistance * 1.12);
        newCameraPosition[2] = savedFocalPoint[2] - directionOfProjection[2]*(newDistance * 1.12);
        camera->SetPosition(newCameraPosition);

        newClippingRange[0] = (MAX(savedClippingRange[0] + (newDistance - distance), 100))*.9;
        newClippingRange[1] = savedClippingRange[1] + (newDistance - distance);
        camera->SetClippingRange(newClippingRange);
    }
    
    // set the field of view;
    if (camera->GetUseHorizontalViewAngle()) {
        newViewAngle = (atan(width/newDistance)*2.0) * (180.0/M_PI);
    } else {
        newViewAngle = (atan((width/aspect)/newDistance)*2) * (180.0/M_PI);
    }
    camera->SetViewAngle(newViewAngle);
    
    size[0] = [self bounds].size.width;
    size[1] = [self bounds].size.height;
    // add a transform to make sure we always render the same size
    scaleTransform = vtkTransform::New();
//    scaleTransform->Scale(((double)size[0] / (double)size[1]) * (9.0/16.0), 1, 1);
    scaleTransform->Scale(((double)size[0] / (double)size[1]) * (3.0/4.0), 1, 1);
    camera->SetUserTransform(scaleTransform);
    scaleTransform->Delete();
    
    if (_eye == DaVinciLeftEye) {
        shear[0] = -tan(0.072);
    } else {
        shear[0] = tan(0.072);
    }
    
    camera->SetViewShear(shear);
    _renderWindow->RenderToDaVinciGLView(self, size);
    
    camera->SetViewShear(savedShear);
    camera->SetPosition(savedPosition);
    camera->SetFocalPoint(savedFocalPoint);
    camera->SetClippingRange(savedClippingRange);
    camera->SetViewAngle(savedViewingAngle);
    camera->SetParallelProjection(savedParallelProjection);
    camera->SetUserTransform(savedUserTransform);
    
//    rayCastMapper->SetAutoAdjustSampleDistances(savedAutoAdjustSampleDistances);
//    rayCastMapper->SetImageSampleDistance(savedImageSampleDistance);
//    rayCastMapper->SetSampleDistance(savedSampleDistance);
    
    if (savedUserTransform) {
        savedUserTransform->UnRegister(NULL);
    }
    
//    renderer->GetAspect();
//    renderer->GetOrigin();
//    renderer->GetCenter();
    
//    savedActors->InitTraversal();
//    while ( (actor = savedActors->GetNextActor()) ) {
//        secondRenderer->AddActor(actor);
//    }
//    
//    savedActors->Delete(); 
    
    if (_holdFlush == NO) {
        [_openGLContext flushBuffer];
    }
}

- (void)_VTKCocoaViewWillDrawNotification:(NSNotification *)notification
{
    dontRenderVolumeRenderingOsiriX = 0;
}

- (void)_VTKCocoaViewDidDrawNotification:(NSNotification *)notification
{
    NSView *view;
    
    view = [notification object];
    if (view == _mirroredView) {
        _holdFlush = YES;
        [self display]; // we need to display right now because for "best" rendering the render window has boosted parameters just while rendering this one time
        _holdFlush = NO;
    }
}

- (void)_VTKCocoaViewPostDidDrawNotification:(NSNotification *)notification
{
//	if ([[self openGLContext] view] != self) {
//		[[self openGLContext] setView:self];
//    }
    [[self openGLContext] makeCurrentContext];
//    [self lockFocus];
    [[self openGLContext] flushBuffer];
//    [self unlockFocus];
}

- (daVinciImageQuality)_imageQualityFromVTKVolumeMapper:(vtkFixedPointVolumeRayCastMapper *)mapper
{
    vtkFixedPointVolumeRayCastMapper *rayCastMapper;
    float imageSampleDistance;

    imageSampleDistance = mapper->GetImageSampleDistance();
    
    if (imageSampleDistance < 1.3) {
        return 1;
    } else if (imageSampleDistance < 2) {
        return .79;
    } else if (imageSampleDistance < 3) {
        return .64;
    } else if (imageSampleDistance < 4) {
        return .54;
    } else if (imageSampleDistance < 5) {
        return .36;
    } else if (imageSampleDistance < 6) {
        return .18;
    } else {
        return 0;
    }
}

- (double)_sampleSpacingForImageQuality:(daVinciImageQuality)imageQuality
{
    if (imageQuality == 1.0) {
        return 2;
    } else if (imageQuality >= .5) {
        return 1.2;
    } else if (imageQuality > 0.0) {
        return 2;
    } else {
        return 4;
    }
}


- (BOOL)_snapshotToPath:(NSString *)path
{
    return [[[self screenImage] TIFFRepresentation] writeToFile:path atomically:NO];
}


@end































