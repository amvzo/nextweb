// DisplayRenderer.h
#import <AppKit/AppKit.h>
#import "FPURender.h"

@interface DisplayRenderer : NSView
{
    NSBitmapImageRep* _frameBuffer;
    NSRect _dirtyRect;
}

- (void)renderLayer:(CALayer*)layer useFPU:(BOOL)useFPU;
@end

// DisplayRenderer.m
#import "DisplayRenderer.h"

@implementation DisplayRenderer

- (void)renderLayer:(CALayer*)layer useFPU:(BOOL)useFPU {
    if (useFPU) {
        FPU_enable();
        FPU_transform_vertices(layer.vertices, layer.transform);
        FPU_disable();
    }
    
    [self _compositeLayer:layer];
}

- (void)_compositeLayer:(CALayer*)layer {
    // Use SCSI DMA for direct framebuffer access
    [SCSIDriver blitData:layer.contents 
              toFramebuffer:_frameBuffer 
                  inRect:layer.frame];
}