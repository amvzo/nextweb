#import <Foundation/Foundation.h>

#import "DSPManager.h"
#import <DriverKit/DriverKit.h> // Hypothetical DSP driver

@implementation DSPManager {
    io_connect_t _dspConnection;
}

+ (instancetype)sharedManager {
    static DSPManager* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        // Connect to DSP driver
        kern_return_t ret = IOServiceOpen("DSP56000Driver", 
                                        mach_task_self(), 
                                        0, 
                                        &_dspConnection);
        if (ret != KERN_SUCCESS) {
            NSLog(@"DSP connection failed");
        }
    }
    return self;
}

- (void)sendCommand:(DSPCommand)cmd data:(NSData*)data {
    // Use DMA to transfer data to DSP memory
    DSPTransferDescriptor desc = {
        .command = cmd,
        .srcAddress = [data bytes],
        .length = [data length]
    };
    
    IOConnectCallMethod(_dspConnection, 
                       kDSPSubmitCommand, 
                       NULL, 0, 
                       &desc, sizeof(desc), 
                       NULL, NULL, NULL, NULL);
}

- (NSData*)readResultBuffer:(size_t)size {
    void* buffer = malloc(size);
    IOConnectCallMethod(_dspConnection, 
                       kDSPReadResult, 
                       NULL, 0, 
                       NULL, 0, 
                       buffer, &size, 
                       NULL, NULL);
    return [NSData dataWithBytesNoCopy:buffer length:size];
}

- (BOOL)dspAvailable {
    return _dspConnection != IO_OBJECT_NULL;
}

@end

// DSP command codes
typedef NS_ENUM(NSUInteger, DSPCommand) {
    DSP_CMD_JPEG_DCT,
    DSP_CMD_AES_CRYPTO,
    DSP_CMD_CSS_TRANSFORM,
    DSP_CMD_MEMCPY_DMA
};

@interface DSPManager : NSObject

+ (instancetype)sharedManager;
- (void)sendCommand:(DSPCommand)cmd data:(NSData*)data;
- (NSData*)readResultBuffer:(size_t)size;
- (BOOL)dspAvailable;

@end

@interface DSPManager (FeatureSupport)

// Comprehensive feature availability checks
- (BOOL)supportsJPEGAcceleration;
- (BOOL)supportsCSSMatrixOps;
- (BOOL)supportsAESEncryption;

// Global fallback control
+ (BOOL)forceSoftwareRendering;

@end