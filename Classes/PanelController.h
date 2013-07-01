#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional
- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;
@end

#pragma mark -

@interface PanelController : NSWindowController
<NSWindowDelegate>
{
    BOOL _hasActivePanel;
}

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;
- (NSRect)statusRectForWindow:(NSWindow *)window;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (void)openPanel;
- (void)closePanel;

@end
