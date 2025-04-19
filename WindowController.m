// WindowController.m
// This file implements the WindowController class, managing the browser UI and interactions.

#import "WindowController.h"
#import "ContentView.h"
#import "NetworkFetcher.h"
#import "CredentialStore.h"
#import "CookieManager.h"
#import "BookmarkManager.h"

@implementation WindowController

// Initializes the WindowController with a window, setting up the UI.
- (id)initWithWindow:(NSWindow *)aWindow {
    self = [super init];
    if (self) {
        window = aWindow;

        // Create toolbar (10px height for minimal footprint).
        NSView *toolbar = [[[NSView alloc] initWithFrame:NSMakeRect(0, 560, 800, 30)] autorelease];
        [[window contentView] addSubview:toolbar];

        // Back button: Small, iconic to save space.
        backButton = [[[NSButton alloc] initWithFrame:NSMakeRect(5, 5, 25, 20)] autorelease];
        [backButton setTitle:@"<"];
        [backButton setTarget:self];
        [backButton setAction:@selector(goBack:)];
        [backButton setEnabled:NO];
        [toolbar addSubview:backButton];

        // Forward button.
        forwardButton = [[[NSButton alloc] initWithFrame:NSMakeRect(35, 5, 25, 20)] autorelease];
        [forwardButton setTitle:@">"];
        [forwardButton setTarget:self];
        [forwardButton setAction:@selector(goForward:)];
        [forwardButton setEnabled:NO];
        [toolbar addSubview:forwardButton];

        // Refresh button.
        refreshButton = [[[NSButton alloc] initWithFrame:NSMakeRect(65, 5, 25, 20)] autorelease];
        [refreshButton setTitle:@"R"];
        [refreshButton setTarget:self];
        [refreshButton setAction:@selector(refresh:)];
        [toolbar addSubview:refreshButton];

        // Stop button.
        stopButton = [[[NSButton alloc] initWithFrame:NSMakeRect(95, 5, 25, 20)] autorelease];
        [stopButton setTitle:@"X"];
        [stopButton setTarget:self];
        [stopButton setAction:@selector(stop:)];
        [stopButton setEnabled:NO];
        [toolbar addSubview:stopButton];

        // Home button.
        homeButton = [[[NSButton alloc] initWithFrame:NSMakeRect(125, 5, 25, 20)] autorelease];
        [homeButton setTitle:@"H"];
        [homeButton setTarget:self];
        [homeButton setAction:@selector(goHome:)];
        [toolbar addSubview:homeButton];

        // Address field: Wide for URL entry.
        addressField = [[[NSTextField alloc] initWithFrame:NSMakeRect(155, 5, 500, 20)] autorelease];
        [addressField setStringValue:@"https://"];
        [toolbar addSubview:addressField];

        // Go button.
        goButton = [[[NSButton alloc] initWithFrame:NSMakeRect(660, 5, 25, 20)] autorelease];
        [goButton setTitle:@"Go"];
        [goButton setTarget:self];
        [goButton setAction:@selector(loadURL:)];
        [toolbar addSubview:goButton];

        // Bookmarks button: Pop-up menu.
        bookmarksButton = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(690, 5, 50, 20) pullsDown:YES] autorelease];
        [bookmarksButton setTarget:self];
        [bookmarksButton setAction:@selector(selectBookmark:)];
        [toolbar addSubview:bookmarksButton];

        // Add Credential button.
        addCredentialButton = [[[NSButton alloc] initWithFrame:NSMakeRect(745, 5, 25, 20)] autorelease];
        [addCredentialButton setTitle:@"C"];
        [addCredentialButton setTarget:self];
        [addCredentialButton setAction:@selector(addCredential:)];
        [toolbar addSubview:addCredentialButton];

        // Scroll view for content.
        scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0, 20, 800, 540)] autorelease];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [scrollView setAutohidesScrollers:YES];
        [[window contentView] addSubview:scrollView];

        // Content view for HTML rendering.
        contentView = [[[ContentView alloc] initWithFrame:NSMakeRect(0, 0, 800, 540)] autorelease];
        [scrollView setDocumentView:contentView];

        // Status bar: Displays progress and errors.
        statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 800, 20)] autorelease];
        [statusField setEditable:NO];
        [statusField setStringValue:@"Ready"];
        [[window contentView] addSubview:statusField];

        // Initialize fetcher for HTML.
        fetcher = [[NetworkFetcher alloc] initWithDelegate:self];
        [fetcher setIsImageFetch:NO];

        // Initialize image fetcher.
        NetworkFetcher *imageFetcher = [[NetworkFetcher alloc] initWithDelegate:contentView];
        [imageFetcher setIsImageFetch:YES];
        [(ContentView *)contentView setImageFetcher:imageFetcher];
        [imageFetcher release];

        // Initialize credential store.
        credentialStore = [[CredentialStore alloc] initWithFilePath:[@"~/data/credentials.dat" stringByExpandingTildeInPath]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[credentialStore valueForKey:@"filePath"]]) {
            masterPassword = [self promptForMasterPassword:@"Set Master Password"];
            if (masterPassword) [credentialStore setupWithMasterPassword:masterPassword];
        }

        // Initialize cookie manager.
        cookieManager = [[CookieManager alloc] initWithFilePath:[@"~/data/cookies.dat" stringByExpandingTildeInPath]];
        [fetcher setCookieManager:cookieManager];

        // Initialize bookmark manager.
        bookmarkManager = [[BookmarkManager alloc] initWithFilePath:[@"~/data/bookmarks.dat" stringByExpandingTildeInPath]];
        [self updateBookmarksMenu];

        // Initialize history.
        history = [[NSMutableArray alloc] init];
        historyIndex = -1;
        isLoading = NO;
    }
    return self;
}

// Deallocates memory.
- (void)dealloc {
    [fetcher release];
    [history release];
    [credentialStore release];
    [cookieManager release];
    [bookmarkManager release];
    [masterPassword release];
    [super dealloc];
}

// Prompts for master password.
- (NSString *)promptForMasterPassword:(NSString *)title {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:title];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSTextField *input = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)] autorelease];
    [input setSecureTextEntry:YES];
    [alert setAccessoryView:input];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        return [[input stringValue] copy];
    }
    return nil;
}

// Loads the URL from the address field.
- (void)loadURL:(id)sender {
    NSString *urlString = [addressField stringValue];
    if (historyIndex < [history count] - 1) {
        [history removeObjectsInRange:NSMakeRange(historyIndex + 1, [history count] - historyIndex - 1)];
    }
    [history addObject:urlString];
    historyIndex++;
    isLoading = YES;
    [stopButton setEnabled:YES];
    [self updateStatus:@"Loading..."];
    [fetcher fetchURL:urlString];
    [backButton setEnabled:(historyIndex > 0)];
    [forwardButton setEnabled:(historyIndex < [history count] - 1)];
}

// Navigates back in history.
- (void)goBack:(id)sender {
    if (historyIndex > 0) {
        historyIndex--;
        NSString *urlString = [history objectAtIndex:historyIndex];
        [addressField setStringValue:urlString];
        isLoading = YES;
        [stopButton setEnabled:YES];
        [self updateStatus:@"Loading..."];
        [fetcher fetchURL:urlString];
        [backButton setEnabled:(historyIndex > 0)];
        [forwardButton setEnabled:(historyIndex < [history count] - 1)];
    }
}

// Navigates forward in history.
- (void)goForward:(id)sender {
    if (historyIndex < [history count] - 1) {
        historyIndex++;
        NSString *urlString = [history objectAtIndex:historyIndex];
        [addressField setStringValue:urlString];
        isLoading = YES;
        [stopButton setEnabled:YES];
        [self updateStatus:@"Loading..."];
        [fetcher fetchURL:urlString];
        [backButton setEnabled:(historyIndex > 0)];
        [forwardButton setEnabled:(historyIndex < [history count] - 1)];
    }
}

// Reloads the current page.
- (void)refresh:(id)sender {
    if (historyIndex >= 0 && historyIndex < [history count]) {
        NSString *urlString = [history objectAtIndex:historyIndex];
        isLoading = YES;
        [stopButton setEnabled:YES];
        [self updateStatus:@"Loading..."];
        [fetcher fetchURL:urlString];
    }
}

// Stops page loading.
- (void)stop:(id)sender {
    if (isLoading) {
        [fetcher cancelFetch];  // Assumes a cancel method (added later).
        isLoading = NO;
        [stopButton setEnabled:NO];
        [self updateStatus:@"Stopped"];
    }
}

// Loads the home page.
- (void)goHome:(id)sender {
    NSString *homeURL = @"https://www.example.com";
    [addressField setStringValue:homeURL];
    [self loadURL:nil];
}

// Handles bookmark selection.
- (void)selectBookmark:(id)sender {
    NSPopUpButton *popup = (NSPopUpButton *)sender;
    NSString *title = [[popup selectedItem] title];
    if ([title isEqualToString:@"Bookmarks"]) return;
    if ([title isEqualToString:@"Add Bookmark"]) {
        NSString *currentURL = [addressField stringValue];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Add Bookmark"];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)] autorelease];
        [titleField setStringValue:currentURL];
        [alert setAccessoryView:titleField];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [bookmarkManager addBookmarkWithTitle:[titleField stringValue] url:currentURL];
            [self updateBookmarksMenu];
        }
    } else {
        NSArray *bookmarks = [bookmarkManager allBookmarks];
        for (NSDictionary *bookmark in bookmarks) {
            if ([[bookmark objectForKey:@"title"] isEqualToString:title]) {
                [addressField setStringValue:[bookmark objectForKey:@"url"]];
                [self loadURL:nil];
                break;
            }
        }
    }
}

// Prompts to add a credential.
- (void)addCredential:(id)sender {
    if (!masterPassword) {
        masterPassword = [self promptForMasterPassword:@"Enter Master Password"];
        if (!masterPassword) return;
    }
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Add Credential"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSTextField *siteField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 60, 200, 24)] autorelease];
    NSTextField *userField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 30, 200, 24)] autorelease];
    NSTextField *passField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)] autorelease];
    [passField setSecureTextEntry:YES];
    NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 90)] autorelease];
    [view addSubview:siteField];
    [view addSubview:userField];
    [view addSubview:passField];
    [alert setAccessoryView:view];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *site = [siteField stringValue];
        NSString *username = [userField stringValue];
        NSString *password = [passField stringValue];
        if ([credentialStore addCredential:site username:username password:password withMasterPassword:masterPassword]) {
            NSLog(@"Credential added for %@", site);
        } else {
            NSLog(@"Failed to add credential: Incorrect master password?");
        }
    }
}

// Updates the status bar.
- (void)updateStatus:(NSString *)status {
    [statusField setStringValue:status];
}

// Updates the bookmarks menu.
- (void)updateBookmarksMenu {
    [bookmarksButton removeAllItems];
    [bookmarksButton addItemWithTitle:@"Bookmarks"];
    [bookmarksButton addItemWithTitle:@"Add Bookmark"];
    NSArray *bookmarks = [bookmarkManager allBookmarks];
    for (NSDictionary *bookmark in bookmarks) {
        [bookmarksButton addItemWithTitle:[bookmark objectForKey:@"title"]];
    }
}

// Delegate method for HTML data.
- (void)didReceiveData:(NSString *)data {
    isLoading = NO;
    [stopButton setEnabled:NO];
    [self updateStatus:@"Done"];
    [(ContentView *)contentView setHTMLContent:data];
}

// Delegate method for errors.
- (void)didFailWithError:(NSString *)error {
    isLoading = NO;
    [stopButton setEnabled:NO];
    [self updateStatus:[NSString stringWithFormat:@"Error: %@", error]];
    [(ContentView *)contentView setHTMLContent:[NSString stringWithFormat:@"Error: %@", error]];
}

@end