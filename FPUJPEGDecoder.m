#import <Foundation/Foundation.h>
#import "FPUMath.h"

@interface FPUJPEGDecoder : NSObject
{
    NSInputStream* _scsiStream;
    FPU_DCTMatrix* _dctBuffer;
    NSMutableData* _pixelBuffer;
}

- (instancetype)initWithSCSISource:(NSInputStream*)stream;
- (NSImage*)decodeProgressiveJPEG;
@end

@implementation FPUJPEGDecoder

- (void)_processDCTBlock:(JPEGBlock*)block {
    FPU_enable();
    
    // 68040-optimized DCT using FMOVEM instructions
    FPU_load_matrix(block->data);
    FPU_fdct();
    FPU_store_matrix(_dctBuffer);
    
    FPU_disable();
    
    [self _dequantizeBlock:_dctBuffer usingTable:block->quantTable];
}

- (void)_decodeMCU:(JPEGMCU*)mcu {
    // Interleaved FPU/SCSI pipeline
    [SCSIDriver scheduleDMA:mcu->data];
    
    while(!SCSIDriver_DMAComplete()) {
        FPU_enable();
        FPU_idct();
        FPU_disable();
        [self _mergeColorComponents];
    }
}

@end