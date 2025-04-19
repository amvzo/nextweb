@interface HybridCompressor : NSObject
{
    LZ4_Stream* _lz4Stream;
    FPU_DeflateState* _fpuState;
}

- (NSData*)compressData:(NSData*)input;
@end

@implementation HybridCompressor

- (NSData*)compressData:(NSData*)input {
    NSMutableData* output = [NSMutableData new];
    
    // Stage 1: LZ4 Fast Compression
    [self _lz4Compress:input to:output];
    
    // Stage 2: FPU-optimized Deflate
    FPU_enable();
    [self _fpuDeflate:output];
    FPU_disable();
    
    return output;
}

- (void)_fpuDeflate:(NSMutableData*)data {
    FPU_load_buffer(data.mutableBytes, data.length);
    FPU_deflate(_fpuState);
    FPU_store_buffer(data.mutableBytes);
    data.length = _fpuState->compressedSize;
}

@end