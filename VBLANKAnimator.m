#import <driverKit/i386/IODisplay.h>

@interface VBLANKAnimator : NSObject
{
    IODisplay* _display;
    NSMutableArray* _animationQueue;
    FPU_Matrix _transformCache;
}

- (void)scheduleAnimation:(CSSAnimation*)anim;
- (void)vblankInterruptHandler;
@end

@implementation VBLANKAnimator

- (void)vblankInterruptHandler {
    IODisplayEnterVBL(_display);
    
    FPU_enable();
    [self _updateTransforms];
    FPU_disable();
    
    [self _swapBuffers];
    IODisplayExitVBL(_display);
}

- (void)_updateTransforms {
    // FPU-accelerated matrix ops
    foreach(CSSAnimation* anim in _animationQueue) {
        FPU_load_matrix(anim->currentMatrix);
        FPU_mult_matrix(anim->transformMatrix);
        FPU_store_matrix(anim->currentMatrix);
    }
}

@end