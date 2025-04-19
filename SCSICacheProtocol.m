#define SCSI_CACHE_BLOCK_SIZE 512 // Match sector size

@interface SCSICacheProtocol : NSObject
{
    NSMutableDictionary* _index;
    SCSIDevice* _cacheDevice;
}

- (void)writeCacheObject:(CacheObject*)obj;
- (CacheObject*)readCacheObject:(NSString*)key;
@end

@implementation SCSICacheProtocol

- (void)writeCacheObject:(CacheObject*)obj {
    SCSICacheHeader header = {
        .magic = 0xCAC1E5ED,
        .compressedSize = [obj data].length,
        .crc = FPU_crc32([obj data])
    };
    
    [SCSIDriver writeBlock:header.block 
                 data:[self _packHeader:header 
                                data:[obj data]] 
                immediate:YES];
}

- (NSData*)_packHeader:(SCSICacheHeader)header data:(NSData*)data {
    NSMutableData* packed = [NSMutableData dataWithLength:
        sizeof(SCSICacheHeader) + header.compressedSize];
        
    FPU_enable();
    FPU_memcpy(packed.mutableBytes, &header, sizeof(header));
    FPU_memcpy(packed.mutableBytes + sizeof(header), 
              data.bytes, data.length);
    FPU_disable();
    
    return packed;
}

@end