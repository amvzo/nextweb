// BookmarkManager.h
// This header file defines the interface for the BookmarkManager class, handling bookmarks.

#import <Foundation/Foundation.h>

@interface BookmarkManager : NSObject {
    NSString *filePath;              // Path to the bookmarks file.
    NSMutableArray *bookmarks;       // Array of bookmark dictionaries.
}

// Method declarations:
- (id)initWithFilePath:(NSString *)path;                     // Initializes with a file path.
- (void)loadBookmarks;                                       // Loads bookmarks from disk.
- (void)saveBookmarks;                                       // Saves bookmarks to disk.
- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url; // Adds a new bookmark.
- (NSArray *)allBookmarks;                                   // Returns all bookmarks.
- (void)removeBookmarkAtIndex:(NSUInteger)index;             // Removes a bookmark.

@end