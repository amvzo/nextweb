#import "KeychainStore.h"
#import "CryptoUtils.h"

@implementation KeychainStore

+ (void)savePassword:(NSString *)password forService:(NSString *)service account:(NSString *)account {
    NSString *key = [NSString stringWithFormat:@"%@:%@", service, account];
    NSString *encrypted = [CryptoUtils encryptString:password withKey:@"MasterKey"];
    [[NSUserDefaults standardUserDefaults] setObject:encrypted forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)loadPasswordForService:(NSString *)service account:(NSString *)account {
    NSString *key = [NSString stringWithFormat:@"%@:%@", service, account];
    NSString *encrypted = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (encrypted) {
        return [CryptoUtils decryptString:encrypted withKey:@"MasterKey"];
    }
    return nil;
}

@end
