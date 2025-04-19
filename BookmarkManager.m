// BookmarkManager.m
// This file implements the BookmarkManager class for managing bookmarks.

#import "BookmarkManager.h"

@implementation BookmarkManager

// Initializes the BookmarkManager with a file path.
- (id)initWithFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        filePath = [path copy];             // Store the file path.
        bookmarks = [[NSMutableArray alloc] init]; // Initialize bookmark array.
        [self loadBookmarks];               // Load existing bookmarks.
    }
    return self;
}

// Deallocates memory for retained objects.
- (void)dealloc {
    [filePath release];
    [bookmarks release];
    [super dealloc];
}

// Loads bookmarks from disk.
- (void)loadBookmarks {
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (fileData) {
        NSArray *storedBookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
        if (storedBookmarks) {
            [bookmarks removeAllObjects];
            [bookmarks addObjectsFromArray:storedBookmarks];
        }
    }
}

// Saves bookmarks to disk.
- (void)saveBookmarks {
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:bookmarks];
    [fileData writeToFile:filePath atomically:YES];
}

// Adds a new bookmark with title and URL.
- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url {
    NSDictionary *bookmark = @{@"title": title, @"url": url};
    [bookmarks addObject:bookmark];
    [self saveBookmarks];
}

// Returns all bookmarks.
- (NSArray *)allBookmarks {
    return bookmarks;
}

// Removes a bookmark at the specified index.
- (void)removeBookmarkAtIndex:(NSUInteger)index {
    if (index < [bookmarks count]) {
        [bookmarks removeObjectAtIndex:index];
        [self saveBookmarks];
    }
}

@end