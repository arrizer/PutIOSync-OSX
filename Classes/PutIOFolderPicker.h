
#import "PutIOAPI.h"
#import "PutIOAPIFile.h"

@class PutIOFolderPicker;
@protocol PutIOFolderPickerDelegate <NSObject>
-(void)folderPicker:(PutIOFolderPicker*)picker didPickFolder:(PutIOAPIFile*)folder;
-(void)folderPicker:(PutIOFolderPicker *)picker didPickFolderID:(int)folderID;
-(void)folderPickerDidCancel:(PutIOFolderPicker*)picker;
@end

@interface PutIOFolderPicker : NSWindowController
<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    PutIOAPIFile *folderTree;
    
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSButton *chooseButton;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSProgressIndicator *activitySpinner;
}

@property (unsafe_unretained) id<PutIOFolderPickerDelegate>delegate;
@property (assign, nonatomic) NSInteger pendingFetches;

- (IBAction)chooseSelectedFolder:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)updateFolders;

@end
