// TLSEngine.h
#import <Foundation/Foundation.h>

@interface TLSEngine : NSObject
{
    NSData* _precomputedPrimes;
    FPUContext* _fpuContext;
}

- (NSData*)performHandshake:(NSInputStream*)input output:(NSOutputStream*)output;
- (NSData*)encryptRecord:(NSData*)record;
@end

// TLSEngine.m
#import "TLSEngine.h"

@implementation TLSEngine

- (NSData*)_computeRSASignature:(NSData*)handshake {
    FPU_enable();
    // Use Montgomery reduction optimized for 68040
    NSData* sig = FPU_rsa_sign(handshake, _privateKey);
    FPU_disable();
    return sig;
}

- (void)_precomputePrimes {
    // Cache primes in SCSI drive during idle time
    if (!_precomputedPrimes) {
        _precomputedPrimes = [SCSIDriver readPrecomputedPrimes];
    }
}