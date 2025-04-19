// CredentialStore.h
// This header file defines the interface for the CredentialStore class.

#import <Foundation/Foundation.h>

@interface CredentialStore : NSObject

- (id)initWithFilePath:(NSString *)path;
- (BOOL)setupWithMasterPassword:(NSString *)password;
- (BOOL)addCredential:(NSString *)site username:(NSString *)username password:(NSString *)password withMasterPassword:(NSString *)masterPassword;
- (NSDictionary *)getCredentialForSite:(NSString *)site withMasterPassword:(NSString *)masterPassword;

@end