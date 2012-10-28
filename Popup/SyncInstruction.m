
#import "SyncInstruction.h"

@implementation SyncInstruction

- (id)init
{
    self = [super init];
    if (self) {
        self.localDestinationIsStale = NO;
        self.deleteRemoteFilesAfterSync = YES;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    
    self.originFolderID = [decoder decodeIntegerForKey:@"originFolderID"];
    self.originFolderName = [decoder decodeObjectForKey:@"originFolderName"];
    self.deleteRemoteFilesAfterSync = [decoder decodeBoolForKey:@"deleteRemoteFilesAfterSync"];
    
    // Resolve the previously stored bookmark
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:[decoder decodeObjectForKey:@"localDestinationBookmark"]
                                                   options:NSURLBookmarkResolutionWithoutUI
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&_localDestinationIsStale
                                                     error:&error];
    if (self.localDestinationIsStale || (error != nil)) {
        _bookmarkResolveError = error;
    }else{
        self.localDestination = url;
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.originFolderID forKey:@"originFolderID"];
    [coder encodeObject:self.originFolderName forKey:@"originFolderName"];
    [coder encodeBool:self.deleteRemoteFilesAfterSync forKey:@"deleteRemoteFilesAfterSync"];
    NSData *bookmark = [self.localDestination bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                                       includingResourceValuesForKeys:nil
                                                        relativeToURL:nil
                                                                error:nil];
    [coder encodeObject:bookmark forKey:@"localDestinationBookmark"];
}

-(id)copyWithZone:(NSZone *)zone
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

@end
