
#import "MASPreferencesViewController.h"

extern NSString *const kMASPreferencesWindowControllerDidChangeViewNotification;

@interface MASPreferencesWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate>

@property (nonatomic, readonly) NSArray *viewControllers;
@property (nonatomic, readonly) NSUInteger indexOfSelectedController;
@property (nonatomic, readonly, retain) NSViewController <MASPreferencesViewController> *selectedViewController;
@property (nonatomic, readonly) NSString *title;

- (instancetype)initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)initWithViewControllers:(NSArray *)viewControllers;
- (instancetype)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title;

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex;

- (IBAction)goNextTab:(id)sender;
- (IBAction)goPreviousTab:(id)sender;

@end
