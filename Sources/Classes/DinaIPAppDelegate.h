/////////////////////////////////////////////////////////////////////////////////
//
//  DinaIPAppDelegate.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file DinaIPAppDelegate.h

@class MainWindowController;
@class PreferencesWindowController;
@class StatusItemController;
@class LoginWindowController;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents a NSApp application delegate object
@interface DinaIPAppDelegate : NSObject <NSApplicationDelegate> 
{
	@private
		MainWindowController *mainController; //!< main window controller
        PreferencesWindowController *preferencesController; //!< preferences controller
        StatusItemController *statusController; //!< status item controller
        LoginWindowController *loginController; //!< login screen controller
}

//! Provides preferences window controller
@property (nonatomic, readonly) PreferencesWindowController *preferencesController;
//! Provides main window controller
@property (nonatomic, readonly) MainWindowController *mainController;

//! Shows preferences window
- (IBAction)showPreferences:(id)aSender;
//! Shows main window
- (IBAction)showMainWindow:(id)aSender;

//! Switch on/off checking local IP by every call
- (IBAction)toggleCheckingIP:(id)aSender;
//! Switch off checking local IP
- (IBAction)resumeService:(id)aSender;
//! Switch on checking local IP
- (IBAction)stopService:(id)aSender;
@end
