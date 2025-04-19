#import "DSPManager.h"

@interface ImageDecoder : NSObject

- (NSImage*)decodeJPEGWithDSP:(NSData*)jpegData;

@end

// ImageDecoder.m
@implementation ImageDecoder

- (NSImage*)decodeJPEGWithDSP:(NSData*)jpegData {
    if ([[DSPManager sharedManager] dspAvailable]) {
        // Offload DCT to DSP
        [[DSPManager sharedManager] sendCommand:DSP_CMD_JPEG_DCT 
                                      data:jpegData];
        
        // Process while waiting for DSP
        NSData* dctData = [[DSPManager sharedManager] 
                          readResultBuffer:jpegData.length];
        
        return [self _processDCTResults:dctData];
    }
    else {
        // Fallback to software
        return [self decodeJPEGSoftware:jpegData];
    }
}

- (NSImage*)_processDCTResults:(NSData*)dctData {
    // Convert DSP56000 fixed-point output to floats
    int24_t* dctCoefficients = (int24_t*)dctData.bytes;
    float* floatCoefficients = malloc(dctData.length * sizeof(float));
    
    for (int i = 0; i < dctData.length/sizeof(int24_t); i++) {
        // Use DSP's 24-bit fixed-point format
        floatCoefficients[i] = dctCoefficients[i] / (float)(1 << 23);
    }
    
    // Continue with IDCT and color space conversion
    return [self _convertColorSpace:floatCoefficients];
}

@end

- (NSImage*)decodeImageData:(NSData*)data {
    DSP_TRY_CATCH(JPEGAcceleration, decode, data)
}

// DSP-accelerated path
- (NSImage*)decodeWithDSP:(NSData*)data {
    if(![self validateJPEGHeader:data]) {
        [NSException raise:@"InvalidJPEG" format:@"Bad JPEG structure"];
    }
    
    // DSP-specific processing
    [[DSPManager sharedManager] sendCommand:DSP_CMD_JPEG_DCT data:data];
    NSData* processed = [[DSPManager sharedManager] readResultBuffer:data.length];
    return [self convertDCTToImage:processed];
}

// CPU fallback
- (NSImage*)decodeWithoutDSP:(NSData*)data {
    JPEGDecoder* softDecoder = [JPEGDecoder new];
    NSImage* result = [softDecoder softwareDecode:data];
    [softDecoder release];
    return result;
}