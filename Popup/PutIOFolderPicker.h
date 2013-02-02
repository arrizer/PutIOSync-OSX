
#import <Cocoa/Cocoa.h>
#import "PutIOAPI.h"

@class PutIOFolderPicker;
@protocol PutIOFolderPickerDelegate <NSObject>
-(void)folderPicker:(PutIOFolderPicker*)picker didPickFolder:(PutIOAPIFile*)folder;
-(void)folderPickerDidCancel:(PutIOFolderPicker*)picker;
@end

@interface PutIOFolderPicker : NSWindowController
<PutIOAPIDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    PutIOAPI *putio;
    NSMutableArray *fileQueue;
    NSTreeNode *folderTree;
    
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSButton *chooseButton;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSProgressIndicator *activitySpinner;
}

@property (unsafe_unretained) id<PutIOFolderPickerDelegate>delegate;

- (IBAction)chooseSelectedFolder:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)updateFolders;

@end
