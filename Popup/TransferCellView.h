
#import <Cocoa/Cocoa.h>
#import "PutIOAPITransfer.h"

@interface TransferCellView : NSTableCellView
{
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSButton *cancelButton;
}

- (IBAction)cancelTransfer:(id)sender;

@end
