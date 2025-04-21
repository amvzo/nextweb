#import <Foundation/Foundation.h>

@interface TLSHandler : NSObject {
}
+ (BOOL)validateServerTrust:(void *)serverTrust forDomain:(NSString *)domain;
@end
