// WindowController.h
// This header file defines the interface for the WindowController class, managing the browser's UI.

#import <AppKit/AppKit.h>

// Forward declarations to avoid circular dependencies.
@class NetworkFetcher;
@class CredentialStore;
@class CookieManager;
@class BookmarkManager;

@interface WindowController : NSObject {
    // UI elements:
    NSWindow *window;              // Main browser window.
    NSTextField *addressField;     // Field for URL entry.
    NSButton *goButton;            // Button to load URL.
    NSButton *backButton;          // Button to navigate back.
    NSButton *forwardButton;       // Button to navigate forward.
    NSButton *refreshButton;       // Button to reload page.
    NSButton *stopButton;          // Button to stop loading.
    NSButton *homeButton;          // Button to return to home page.
    NSPopUpButton *bookmarksButton;// Button for bookmark menu.
    NSButton *addCredentialButton; // Button to add credentials.
    NSScrollView *scrollView;      // Scrollable view for content.
    NSView *contentView;           // View for HTML rendering.
    NSTextField *statusField;      // Status bar for progress and errors.

    // Functional components:
    NetworkFetcher *fetcher;       // Fetcher for HTML content.
    CredentialStore *credentialStore; // Manager for credentials.
    CookieManager *cookieManager;  // Manager for cookies.
    BookmarkManager *bookmarkManager; // Manager for bookmarks.
    NSMutableArray *history;       // Array of visited URLs.
    int historyIndex;              // Current history position.
    NSString *masterPassword;      // Temporary master password storage.
    BOOL isLoading;                // Flag for page loading state.
}

// Method declarations:
- (id)initWithWindow:(NSWindow *)aWindow;       // Initializes with a window.
- (void)loadURL:(id)sender;                     // Loads URL from address field.
- (void)goBack:(id)sender;                      // Navigates back.
- (void)goForward:(id)sender;                   // Navigates forward.
- (void)refresh:(id)sender;                     // Reloads page.
- (void)stop:(id)sender;                        // Stops loading.
- (void)goHome:(id)sender;                      // Loads home page.
- (void)selectBookmark:(id)sender;              // Loads selected bookmark.
- (void)addCredential:(id)sender;               // Prompts to add credential.
- (void)updateStatus:(NSString *)status;        // Updates status bar.
- (void)updateBookmarksMenu;                    // Updates bookmark menu.

@end