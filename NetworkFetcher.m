// NetworkFetcher.m
// This file implements the NetworkFetcher class with HTTPS support.

#import "NetworkFetcher.h"
#import "CookieManager.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

@implementation NetworkFetcher

- (id)initWithDelegate:(id)aDelegate {
    self = [super init];
    if (self) {
        delegate = aDelegate;
        isImageFetch = NO;
        cookieManager = nil;
        ssl = NULL;
        ctx = NULL;
        sockfd = -1;
        SSL_library_init();
        OpenSSL_add_all_algorithms();
        SSL_load_error_strings();
    }
    return self;
}

- (void)setIsImageFetch:(BOOL)flag {
    isImageFetch = flag;
}

- (void)setCookieManager:(CookieManager *)manager {
    cookieManager = manager;
}

- (void)cancelFetch {
    if (ssl) {
        SSL_shutdown(ssl);
        SSL_free(ssl);
        ssl = NULL;
    }
    if (ctx) {
        SSL_CTX_free(ctx);
        ctx = NULL;
    }
    if (sockfd >= 0) {
        close(sockfd);
        sockfd = -1;
    }
}

- (void)fetchURL:(NSString *)urlString {
    [self cancelFetch]; // Ensure previous connections are closed.

    NSURL *url = [NSURL URLWithString:urlString];
    NSString *host = [url host];
    NSString *path = [url path] ?: @"/";
    BOOL isHTTPS = [[url scheme] isEqualToString:@"https"];
    int port = isHTTPS ? 443 : 80;

    struct hostent *hostEntry = gethostbyname([host UTF8String]);
    if (!hostEntry) {
        [delegate didFailWithError:@"Failed to resolve host"];
        return;
    }
    struct in_addr *addr = (struct in_addr *)hostEntry->h_addr_list[0];

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        [delegate didFailWithError:@"Failed to create socket"];
        return;
    }

    struct sockaddr_in serv_addr = {0};
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(port);
    serv_addr.sin_addr = *addr;

    if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        close(sockfd);
        sockfd = -1;
        [delegate didFailWithError:@"Connection failed"];
        return;
    }

    if (isHTTPS) {
        ctx = SSL_CTX_new(SSLv23_client_method());
        if (!ctx) {
            close(sockfd);
            sockfd = -1;
            [delegate didFailWithError:@"Failed to create SSL context"];
            return;
        }
        ssl = SSL_new(ctx);
        if (!ssl) {
            SSL_CTX_free(ctx);
            ctx = NULL;
            close(sockfd);
            sockfd = -1;
            [delegate didFailWithError:@"Failed to create SSL object"];
            return;
        }
        SSL_set_fd(ssl, sockfd);
        if (SSL_connect(ssl) <= 0) {
            SSL_free(ssl);
            ssl = NULL;
            SSL_CTX_free(ctx);
            ctx = NULL;
            close(sockfd);
            sockfd = -1;
            [delegate didFailWithError:[NSString stringWithFormat:@"SSL connection failed: %s", ERR_error_string(ERR_get_error(), NULL)]];
            return;
        }
    }

    NSString *cookieHeader = [cookieManager cookieHeaderForURL:urlString];
    NSString *request = cookieHeader ?
        [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\nHost: %@\r\nCookie: %@\r\nConnection: close\r\n\r\n", path, host, cookieHeader] :
        [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\nHost: %@\r\nConnection: close\r\n\r\n", path, host];
    
    if (isHTTPS) {
        SSL_write(ssl, [request UTF8String], [request length]);
    } else {
        write(sockfd, [request UTF8String], [request length]);
    }

    NSMutableData *responseData = [NSMutableData data];
    char buffer[1024];
    int bytes;
    while ((isHTTPS ? (bytes = SSL_read(ssl, buffer, sizeof(buffer) - 1)) : (bytes = read(sockfd, buffer, sizeof(buffer) - 1))) > 0) {
        buffer[bytes] = '\0';
        [responseData appendBytes:buffer length:bytes];
        [delegate didUpdateTotalProgress:((float)[responseData length] / 1000000.0) bytesReceived:[responseData length] totalBytes:1000000];
    }
    if (bytes < 0) {
        [self cancelFetch];
        [delegate didFailWithError:@"Failed to read response"];
        return;
    }

    NSString *response = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
    NSArray *lines = [response componentsSeparatedByString:@"\r\n"];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"Set-Cookie:"]) {
            NSString *cookieLine = [line substringFromIndex:11];
            [cookieManager setCookieFromHeader:cookieLine forURL:urlString];
        }
    }

    if (isImageFetch) {
        [delegate didReceiveImageData:responseData forURL:urlString];
    } else {
        [delegate didReceiveData:response];
    }
    [response release];

    [self cancelFetch];
}

@end