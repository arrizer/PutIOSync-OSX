#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional
- (NSView *)statusItemViewForPanelController:(PanelController *)controller;
@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>

- (instancetype)initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(id<PanelControllerDelegate>)delegate;
- (NSRect)statusRectForWindow:(NSWindow *)window;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained, readwrite) id<PanelControllerDelegate> delegate;

- (void)openPanel;
- (void)closePanel;

@end
