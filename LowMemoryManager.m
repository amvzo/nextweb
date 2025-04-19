// LowMemoryManager.m
#import "DSPManager.h"
#import <Foundation/Foundation.h>

#import "LowMemoryManager.h"
#import "SCSIDriver.h"

@interface LowMemoryManager : NSObject
{
    NSMutableSet* _compressibleBuffers;
    NSUInteger _memoryPressureLevel;
}

+ (instancetype)sharedManager;
- (void)registerCompressibleBuffer:(NSMutableData*)buffer;
- (void)handleMemoryWarning;
@end

// LowMemoryManager.m
#import "LowMemoryManager.h"
#import "SCSIDriver.h"

@implementation LowMemoryManager

- (void)handleMemoryWarning {
    // Compress using SCSI drive's hardware compression
    for (NSMutableData* buffer in _compressibleBuffers) {
        NSData* compressed = [SCSIDriver compressData:buffer];
        [buffer setData:compressed];
    }
    
    // Purge FPU-allocated memory
    FPU_release_cache();
}

@end

@implementation LowMemoryManager

- (void)handleMemoryWarning {
    // Offload compression to DSP
    NSData* compressed = [self _dspCompress:_compressibleBuffers];
    
    // Use SCSI DMA to write compressed data
    [SCSIDriver writeDMA:compressed block:_currentBlock++];
    
    // Free DSP working memory
    [[DSPManager sharedManager] sendCommand:DSP_CMD_FREE_MEM data:nil];
}

- (NSData*)_dspCompress:(NSArray*)buffers {
    NSMutableData* combined = [NSMutableData data];
    for (NSData* buf in buffers) [combined appendData:buf];
    
    [[DSPManager sharedManager] sendCommand:DSP_CMD_LZ_COMPRESS 
                                  data:combined];
    return [[DSPManager sharedManager] 
           readResultBuffer:combined.length/2]; // Estimated ratio
}

@end