// CookieManager.h
// This header file defines the interface for the CookieManager class.

#import <Foundation/Foundation.h>

@interface CookieManager : NSObject {
    NSString *filePath;
    NSMutableDictionary *cookies;
}

- (id)initWithFilePath:(NSString *)path;
- (void)loadCookies;
- (void)saveCookies;
- (void)setCookieFromHeader:(NSString *)header forURL:(NSString *)url;
- (NSString *)cookieHeaderForURL:(NSString *)url;

@end