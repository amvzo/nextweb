// CredentialStore.m
// This file implements the CredentialStore class.

#import "CredentialStore.h"
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/hmac.h>

#define SALT_SIZE 16
#define IV_SIZE 16
#define MAC_SIZE 32
#define KEY_ITERATIONS 10000
#define KEY_LENGTH 64

@implementation CredentialStore {
    NSString *filePath;
}

- (id)initWithFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        filePath = [path copy];
    }
    return self;
}

- (void)dealloc {
    [filePath release];
    [super dealloc];
}

- (NSData *)deriveKeyFromPassword:(NSString *)password salt:(NSData *)salt {
    unsigned char derivedKey[KEY_LENGTH];
    PKCS5_PBKDF2_HMAC([password UTF8String], [password length], [salt bytes], [salt length], KEY_ITERATIONS, EVP_sha256(), KEY_LENGTH, derivedKey);
    return [NSData dataWithBytes:derivedKey length:KEY_LENGTH];
}

- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    EVP_EncryptInit_ex(&ctx, EVP_aes_256_cbc(), NULL, [key bytes], [iv bytes]);
    int outLen;
    unsigned char *ciphertext = malloc([data length] + 16);
    if (!ciphertext) return nil;
    EVP_EncryptUpdate(&ctx, ciphertext, &outLen, [data bytes], [data length]);
    int finalLen;
    EVP_EncryptFinal_ex(&ctx, ciphertext + outLen, &finalLen);
    EVP_CIPHER_CTX_cleanup(&ctx);
    NSData *encryptedData = [NSData dataWithBytes:ciphertext length:outLen + finalLen];
    free(ciphertext);
    return encryptedData;
}

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    EVP_DecryptInit_ex(&ctx, EVP_aes_256_cbc(), NULL, [key bytes], [iv bytes]);
    int outLen;
    unsigned char *plaintext = malloc([data length]);
    if (!plaintext) return nil;
    EVP_DecryptUpdate(&ctx, plaintext, &outLen, [data bytes], [data length]);
    int finalLen;
    if (EVP_DecryptFinal_ex(&ctx, plaintext + outLen, &finalLen) <= 0) {
        free(plaintext);
        EVP_CIPHER_CTX_cleanup(&ctx);
        return nil;
    }
    EVP_CIPHER_CTX_cleanup(&ctx);
    NSData *decryptedData = [NSData dataWithBytes:plaintext length:outLen + finalLen];
    free(plaintext);
    return decryptedData;
}

- (NSData *)computeMACForData:(NSData *)data withKey:(NSData *)key {
    unsigned char mac[MAC_SIZE];
    unsigned int macLen;
    HMAC(EVP_sha256(), [key bytes], [key length], [data bytes], [data length], mac, &macLen);
    return [NSData dataWithBytes:mac length:macLen];
}

- (BOOL)setupWithMasterPassword:(NSString *)password {
    unsigned char salt[SALT_SIZE];
    unsigned char iv[IV_SIZE];
    if (RAND_bytes(salt, SALT_SIZE) != 1 || RAND_bytes(iv, IV_SIZE) != 1) return NO;
    
    NSData *saltData = [NSData dataWithBytes:salt length:SALT_SIZE];
    NSData *derivedKey = [self deriveKeyFromPassword:password salt:saltData];
    NSData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 32)];
    NSData *macKey = [derivedKey subdataWithRange:NSMakeRange(32, 32)];
    
    NSString *emptyCredentials = @"";
    NSData *dataToEncrypt = [emptyCredentials dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self encryptData:dataToEncrypt withKey:encryptionKey iv:[NSData dataWithBytes:iv length:IV_SIZE]];
    if (!encryptedData) return NO;
    
    NSMutableData *macData = [NSMutableData dataWithData:[NSData dataWithBytes:iv length:IV_SIZE]];
    [macData appendData:encryptedData];
    NSData *mac = [self computeMACForData:macData withKey:macKey];
    
    NSMutableData *fileData = [NSMutableData dataWithData:saltData];
    [fileData appendData:[NSData dataWithBytes:iv length:IV_SIZE]];
    [fileData appendData:encryptedData];
    [fileData appendData:mac];
    return [fileData writeToFile:filePath atomically:YES];
}

- (BOOL)addCredential:(NSString *)site username:(NSString *)username password:(NSString *)password withMasterPassword:(NSString *)masterPassword {
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) return NO;
    
    NSData *salt = [fileData subdataWithRange:NSMakeRange(0, SALT_SIZE)];
    NSData *iv = [fileData subdataWithRange:NSMakeRange(SALT_SIZE, IV_SIZE)];
    NSData *encryptedData = [fileData subdataWithRange:NSMakeRange(SALT_SIZE + IV_SIZE, [fileData length] - SALT_SIZE - IV_SIZE - MAC_SIZE)];
    NSData *storedMac = [fileData subdataWithRange:NSMakeRange([fileData length] - MAC_SIZE, MAC_SIZE)];
    
    NSData *derivedKey = [self deriveKeyFromPassword:masterPassword salt:salt];
    NSData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 32)];
    NSData *macKey = [derivedKey subdataWithRange:NSMakeRange(32, 32)];
    
    NSMutableData *macData = [NSMutableData dataWithData:iv];
    [macData appendData:encryptedData];
    NSData *computedMac = [self computeMACForData:macData withKey:macKey];
    if (![computedMac isEqualToData:storedMac]) return NO;
    
    NSData *decryptedData = [self decryptData:encryptedData withKey:encryptionKey iv:iv];
    if (!decryptedData) return NO;
    NSString *credentialsStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    NSString *newCredential = [NSString stringWithFormat:@"%@\n%@:%@:%@", credentialsStr, site, username, password];
    [credentialsStr release];
    NSData *newDataToEncrypt = [newCredential dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char newIv[IV_SIZE];
    if (RAND_bytes(newIv, IV_SIZE) != 1) return NO;
    NSData *newIvData = [NSData dataWithBytes:newIv length:IV_SIZE];
    
    NSData *newEncryptedData = [self encryptData:newDataToEncrypt withKey:encryptionKey iv:newIvData];
    if (!newEncryptedData) return NO;
    
    NSMutableData *newMacData = [NSMutableData dataWithData:newIvData];
    [newMacData appendData:newEncryptedData];
    NSData *newMac = [self computeMACForData:newMacData withKey:macKey];
    
    NSMutableData *newFileData = [NSMutableData dataWithData:salt];
    [newFileData appendData:newIvData];
    [newFileData appendData:newEncryptedData];
    [newFileData appendData:newMac];
    return [newFileData writeToFile:filePath atomically:YES];
}

- (NSDictionary *)getCredentialForSite:(NSString *)site withMasterPassword:(NSString *)masterPassword {
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) return nil;
    
    NSData *salt = [fileData subdataWithRange:NSMakeRange(0, SALT_SIZE)];
    NSData *iv = [fileData subdataWithRange:NSMakeRange(SALT_SIZE, IV_SIZE)];
    NSData *encryptedData = [fileData subdataWithRange:NSMakeRange(SALT_SIZE + IV_SIZE, [fileData length] - SALT_SIZE - IV_SIZE - MAC_SIZE)];
    NSData *storedMac = [fileData subdataWithRange:NSMakeRange([fileData length] - MAC_SIZE, MAC_SIZE)];
    
    NSData *derivedKey = [self deriveKeyFromPassword:masterPassword salt:salt];
    NSData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 32)];
    NSData *macKey = [derivedKey subdataWithRange:NSMakeRange(32, 32)];
    
    NSMutableData *macData = [NSMutableData dataWithData:iv];
    [macData appendData:encryptedData];
    NSData *computedMac = [self computeMACForData:macData withKey:macKey];
    if (![computedMac isEqualToData:storedMac]) return nil;
    
    NSData *decryptedData = [self decryptData:encryptedData withKey:encryptionKey iv:iv];
    if (!decryptedData) return nil;
    NSString *credentialsStr = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    NSArray *lines = [credentialsStr componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByString:@":"];
        if ([parts count] == 3 && [parts[0] isEqualToString:site]) {
            NSDictionary *credential = @{@"username": parts[1], @"password": parts[2]};
            [credentialsStr release];
            return credential;
        }
    }
    [credentialsStr release];
    return nil;
}

@end