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
@property (nonatomic, weak) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, weak, readonly) id<PanelControllerDelegate> delegate;

- (void)openPanel;
- (void)closePanel;

@end
