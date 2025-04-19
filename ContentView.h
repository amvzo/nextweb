// ContentView.h
// This header file defines the interface for the ContentView class.

#import <AppKit/AppKit.h>

@class NetworkFetcher;

@interface ContentView : NSView {
    NSString *currentURL;
    NSString *htmlContent;
    NSMutableArray *linkRects;
    NSMutableArray *linkURLs;
    NSMutableArray *images;
    NSMutableArray *imageRects;
    NetworkFetcher *imageFetcher;
    NSMutableDictionary *pendingImages;
    NSMutableDictionary *imageCache;
    NSMutableArray *imageCacheOrder;
    unsigned long imageCacheSize;
    int totalImages;
    int loadedImages;
    NSSize contentSize;
    unsigned long totalBytesReceived;
    unsigned long totalContentLength;
}

- (id)initWithFrame:(NSRect)frame;
- (void)renderURL:(NSString *)urlString;
- (void)setHTMLContent:(NSString *)html;
- (void)setImageFetcher:(NetworkFetcher *)fetcher;

@end