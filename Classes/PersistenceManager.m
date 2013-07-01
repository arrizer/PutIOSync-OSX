
#import "PersistenceManager.h"

#define APPSUPPORT_SUBDIRECTORY @"/PutIOSync"

@implementation PersistenceManager

+(NSString*)persistentStorageLocationCreateIfNecessary:(BOOL)shoudCreate
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *appSupport = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask][0];
    NSString *path = [[appSupport relativePath] stringByAppendingString:APPSUPPORT_SUBDIRECTORY];
    if(![fm fileExistsAtPath:path]){
        if(shoudCreate){
            NSError *error;
            if(![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]){
                NSLog(@"Unable to create subfolder in Application Support: %@", error);
                return nil;
            }
        }else{
            return nil;
        }
    }
    return path;
}

+(void)storePersistentObject:(id<NSCoding>)object
                      forKey:(NSString *)key
{
    if(object == nil)
        return;
    NSString *path = [PersistenceManager persistentStorageLocationCreateIfNecessary:YES];
    if(path){
        path = [path stringByAppendingFormat:@"/%@.plist", key];
        if([NSKeyedArchiver archiveRootObject:object toFile:path]){
            //NSLog(@"Archived persistent object for key: %@", key);
        }else{
            NSLog(@"Unable to archive persistent object for key: %@", key);            
        }
    }
}

+(id)retrievePersistentObjectForKey:(NSString *)key
{
    NSString *path = [PersistenceManager persistentStorageLocationCreateIfNecessary:NO];
    if(path){
        path = [path stringByAppendingFormat:@"/%@.plist", key];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            id object = nil;
            @try {
                object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            }
            @catch (NSException *exception) {
                NSLog(@"Unable to unarchive persistent object for key %@: %@", key, exception);
            }
            return object;
        }
    }
    return nil;
}
@end
