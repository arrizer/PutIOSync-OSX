
@import Cocoa;
#import "Download.h"

@interface DownloadCellView : NSTableCellView
<NSURLConnectionDataDelegate>
{
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSLayoutConstraint *statusLabelConstraint;
    IBOutlet NSLayoutConstraint *textLabelConstraint;
    IBOutlet NSButton *pauseResumeButton;
    Download *_download;
    NSURLConnection *iconLoader;
    NSMutableData *iconImageData;
}

@property (strong) Download *download;

- (IBAction)pauseOrResumeDownload:(id)sender;

@end
