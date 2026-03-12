//
//  M3GLanguageSelectorController.h
//  MP3Gain Express
//

#import <Cocoa/Cocoa.h>

@interface M3GLanguageSelectorController : NSWindowController

+ (instancetype)sharedController;
- (void)showForWindow:(NSWindow *)parentWindow;

@end
