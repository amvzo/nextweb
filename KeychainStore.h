#import <Foundation/Foundation.h>

@interface KeychainStore : NSObject {
}
+ (void)savePassword:(NSString *)password forService:(NSString *)service account:(NSString *)account;
+ (NSString *)loadPasswordForService:(NSString *)service account:(NSString *)account;
@end
