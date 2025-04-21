#import "TLSHandler.h"

@implementation TLSHandler

+ (BOOL)validateServerTrust:(void *)serverTrust forDomain:(NSString *)domain {
    // Stub: no-op in OpenStep (certificate validation needs custom impl)
    return YES;
}

@end
