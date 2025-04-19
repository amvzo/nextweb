// NetworkFetcher.h
// This header file defines the interface for the NetworkFetcher class with HTTPS.

#import <Foundation/Foundation.h>
#include <openssl/ssl.h>

@class CookieManager;

@interface NetworkFetcher : NSObject {
    id delegate;
    BOOL isImageFetch;
    CookieManager *cookieManager;
    SSL *ssl;              // SSL connection for HTTPS.
    SSL_CTX *ctx;          // SSL context.
    int sockfd;            // Socket for connection.
}

// Method declarations:
- (id)initWithDelegate:(id)aDelegate;
- (void)setIsImageFetch:(BOOL)flag;
- (void)setCookieManager:(CookieManager *)manager;
- (void)fetchURL:(NSString *)urlString;
- (void)cancelFetch;     // Cancels ongoing fetch.

@end

@protocol NetworkFetcherDelegate
- (void)didReceiveData:(NSString *)data;
- (void)didFailWithError:(NSString *)error;
- (void)didReceiveImageData:(NSData *)data forURL:(NSString *)url;
- (void)didUpdateProgress:(float)progress forURL:(NSString *)url;
- (void)didUpdateTotalProgress:(float)progress bytesReceived:(unsigned long)bytes totalBytes:(unsigned long)total;
@end