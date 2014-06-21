
#import "PersistenceManager.h"

#define APPSUPPORT_SUBDIRECTORY @"/PutIOSync"

@implementation PersistenceManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize model = _model;
@synthesize context = _context;

+(instancetype)manager
{
    static PersistenceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PersistenceManager alloc] init];
    });
    return sharedInstance;
}

- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"de.matthiasschwab.putiosync"];
}

- (NSManagedObjectModel *)model
{
    if(_model == nil){
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _model;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *model = self.model;
    if(!model){
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"de.matthiasschwab.putiosync" code:101 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"putiosync.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)context
{
    if(_context){
        return _context;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_context setPersistentStoreCoordinator:coordinator];
    
    return _context;
}

- (void)save
{
    NSError *error = nil;
    if (![self.context commitEditing]){
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    if (![self.context save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (!_context) {
        return NSTerminateNow;
    }
    if (![self.context commitEditing]){
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    if (![self.context hasChanges]){
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![self.context save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

-(NSEntityDescription *)entityNamed:(NSString *)entityName
{
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:self.context];
}

//+(NSString*)persistentStorageLocationCreateIfNecessary:(BOOL)shoudCreate
//{
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSURL *appSupport = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask][0];
//    NSString *path = [[appSupport relativePath] stringByAppendingString:APPSUPPORT_SUBDIRECTORY];
//    if(![fm fileExistsAtPath:path]){
//        if(shoudCreate){
//            NSError *error;
//            if(![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]){
//                NSLog(@"Unable to create subfolder in Application Support: %@", error);
//                return nil;
//            }
//        }else{
//            return nil;
//        }
//    }
//    return path;
//}
//
//+(void)storePersistentObject:(id<NSCoding>)object
//                      forKey:(NSString *)key
//{
//    if(object == nil)
//        return;
//    NSString *path = [PersistenceManager persistentStorageLocationCreateIfNecessary:YES];
//    if(path){
//        path = [path stringByAppendingFormat:@"/%@.plist", key];
//        if([NSKeyedArchiver archiveRootObject:object toFile:path]){
//            //NSLog(@"Archived persistent object for key: %@", key);
//        }else{
//            NSLog(@"Unable to archive persistent object for key: %@", key);            
//        }
//    }
//}
//
//+(id)retrievePersistentObjectForKey:(NSString *)key
//{
//    NSString *path = [PersistenceManager persistentStorageLocationCreateIfNecessary:NO];
//    if(path){
//        path = [path stringByAppendingFormat:@"/%@.plist", key];
//        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
//            id object = nil;
//            @try {
//                object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//            }
//            @catch (NSException *exception) {
//                NSLog(@"Unable to unarchive persistent object for key %@: %@", key, exception);
//            }
//            return object;
//        }
//    }
//    return nil;
//}
@end
