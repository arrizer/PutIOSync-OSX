
#import "PutIOAPIFile.h"

@implementation PutIOAPIFile

-(instancetype)initWithRawData:(id)data
{
    self = [super initWithRawData:data];
    if(self){
        self.fileID = [data[@"id"] integerValue];
        if(data[@"parent_id"] != [NSNull null]){
            self.parentFileID = [data[@"parent_id"] integerValue];
        }else{
            self.parentFileID = -1;
        }
        self.name = data[@"name"];
        self.dateCreated = [PutIOAPIObject dateFromRawDataString:data[@"created_at"]];
        self.contentType = data[@"content_type"];
        if(data[@"icon"] != [NSNull null]){
            self.iconURL = [NSURL URLWithString:data[@"icon"]];
        }else{
            self.iconURL = nil;
        }
        self.size = [data[@"size"] integerValue];
        if(data[@"screenshot"] != [NSNull null])
            self.screenshotURL = [NSURL URLWithString:data[@"screenshot"]];
        if(data[@"is_shared"] != [NSNull null])
            self.isShared = [data[@"is_shared"] boolValue];
        if(data[@"is_mp4_available"] != [NSNull null])
            self.mp4VersionAvailable = [data[@"is_mp4_available"] boolValue];
    }
    return self;
}

-(BOOL)isFolder
{
    return [self.contentType isEqualToString:@"application/x-directory"];
}

-(BOOL)isRootFolder
{
    return (self.isFolder && self.parentFileID == -1);
}

@end
