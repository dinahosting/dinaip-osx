/////////////////////////////////////////////////////////////////////////////////
//
//  LoginWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file LoginWindowController.h

/////////////////////////////////////////////////////////////////////////////////
@class LoginWindowController;
@class LoginDinaDNS;

/////////////////////////////////////////////////////////////////////////////////
//! An interface of LoginWindow controller delegate
@protocol LoginWindowControllerDelegate<NSObject>
//! Called when login did finish successfully
- (void)loginControllerDidConnect:(LoginWindowController *)aController;
//! Called when login did fail for some reason
//- (void)loginControllerDidFail:(LoginWindowController *)aController 
//	error:(NSError *)anError;
@end

/////////////////////////////////////////////////////////////////////////////////
//! This class represents Login window controller
@interface LoginWindowController : NSWindowController 
{
	@private
        id<LoginWindowControllerDelegate> delegate; //!< A delegate object
        LoginDinaDNS *lastMethod; //!< Last called login method
        NSWindow *progressPane; //!< Window showing login progress
        NSWindow *owner; //!< Weak-link. An owner window taking a sheet
        NSProgressIndicator *spinner; //!< Loging Progress indicator
        
        BOOL shouldStoreUsername; //!< A flag for binding
        BOOL shouldStorePassword; //!< A flag for binding
        BOOL shouldAutoconnect; //!< A flag for binding
        BOOL shouldCheckForUpdates; //!< A flag for binding
        
        NSString *identifier; //!< Entered identifier
        NSString *password; //!< Entered password
        NSUInteger loginType; //! Used login type

        NSMutableArray *storedIdentifiers; //!< History of entered identifiers
        NSMutableDictionary *storedInfo; //!< History of entered passwords
}

//! Window with progress indicator
@property (nonatomic, assign) IBOutlet NSWindow *progressPane;
//! Progress indicator
@property (nonatomic, assign) IBOutlet NSProgressIndicator *spinner;

//! Login identifier
@property (nonatomic, retain) NSString *identifier;
//! Login password
@property (nonatomic, retain) NSString *password;
//! Stored identifiers
@property (nonatomic, readonly, retain) NSArray *storedIdentifiers;

//! Indicates if identifier should be stored
@property (nonatomic, assign) BOOL shouldStoreUsername;
//! Indicates if password should be stored
@property (nonatomic, assign) BOOL shouldStorePassword;
//! Indicates if connect automatically next launch time
@property (nonatomic, assign) BOOL shouldAutoconnect;
//! Indicates if check for application update
@property (nonatomic, assign) BOOL shouldCheckForUpdates;
//! Indicates if last stored user has checked autoconnect
@property (nonatomic, readonly) BOOL hasAutoConnect;

//! Shows login type
@property (nonatomic, assign) NSUInteger loginType;

//! Controller's delegate object
@property (nonatomic, assign) id<LoginWindowControllerDelegate> delegate;

//! Accept user action
- (IBAction)accept:(id)aSender;
//! Cancel user action
- (IBAction)cancel:(id)aSender;
//! Cancel progress 
- (IBAction)cancelConnect:(id)aSender;
//! Change identifier from combo-box
- (IBAction)changeIdentifier:(id)aSender;

//! Shows window on the screen
- (void)showWindowModalToWindow:(NSWindow *)aWindow;
//! Initiates connection progress with progress window
- (void)connectModalToWindow:(NSWindow *)aWindow;
//! Initiates silent connect with informing results via delegate
- (void)connect;

//! Provides domains retrieved from a server after login finished
- (NSArray *)domains;
//! Provides version info retrieved from a server
- (NSDictionary *)version;

@end
