@interface SCSIWebPDecoder : NSObject
{
    SCSIDevice* _webpDrive;
    NSMutableData* _clusterBuffer;
}

- (NSImage*)decodeWebPWithSCSIDMA:(BOOL)useDMA;
@end

@implementation SCSIWebPDecoder

- (void)_decodeCluster:(WebPCluster*)cluster {
    if(useDMA) {
        [SCSIDriver readBlock:cluster->block 
                   toBuffer:_clusterBuffer 
                  immediate:NO];
        while([SCSIDriver status] != SCSIStatusComplete) {
            [self _processHeader];
        }
    } else {
        [self _pioDecodeCluster];
    }
}

- (void)_pioDecodeCluster {
    // Use FPU for predictive coding math
    FPU_enable();
    WebPPredictor predictor = [self _calculateBestPredictor];
    FPU_disable();
    
    [self _applyPredictor:predictor];
}

@end