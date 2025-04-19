#import "DSPManager.h"

@interface CSSLayoutEngine : NSObject

- (void)applyTransformsWithDSP:(NSArray<CALayer*>*)layers;

@end

// CSSLayoutEngine.m
@implementation CSSLayoutEngine

- (void)applyTransformsWithDSP:(NSArray<CALayer*>*)layers {
    if (![[DSPManager sharedManager] dspAvailable]) {
        [self applyTransformsSoftware:layers];
        return;
    }
    
    // Prepare transform matrices for DSP
    NSMutableData* matrixData = [NSMutableData data];
    for (CALayer* layer in layers) {
        CATransform3D transform = layer.transform;
        [matrixData appendBytes:&transform length:sizeof(CATransform3D)];
    }
    
    // DSP optimized matrix multiplication
    [[DSPManager sharedManager] sendCommand:DSP_CMD_CSS_TRANSFORM 
                                  data:matrixData];
    
    // Retrieve results
    NSData* result = [[DSPManager sharedManager] 
                     readResultBuffer:matrixData.length];
    
    // Apply transformed matrices to layers
    [self _applyDSPResults:result toLayers:layers];
}

- (void)_applyDSPResults:(NSData*)results toLayers:(NSArray*)layers {
    const CATransform3D* transformed = (CATransform3D*)results.bytes;
    for (NSUInteger i = 0; i < layers.count; i++) {
        ((CALayer*)layers[i]).transform = transformed[i];
    }
}

@end

- (void)applyTransforms:(NSArray<CALayer*>*)layers {
    DSP_TRY_CATCH(CSSMatrixOps, applyTransforms, layers)
}

// DSP-accelerated
- (void)applyTransformsWithDSP:(NSArray<CALayer*>*)layers {
    NSData* matrixData = [self packTransformData:layers];
    [[DSPManager sharedManager] sendCommand:DSP_CMD_CSS_TRANSFORM data:matrixData];
    NSData* result = [[DSPManager sharedManager] readResultBuffer:matrixData.length];
    [self applyOptimizedTransforms:result toLayers:layers];
}

// CPU fallback
- (void)applyTransformsWithoutDSP:(NSArray<CALayer*>*)layers {
    for(CALayer* layer in layers) {
        CATransform3D transform = [self computeTransformSoftware:layer];
        layer.transform = transform;
    }
}

