/////////////////////////////////////////////////////////////////////////////////
//
//  VerifyWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file VerifyWindowController.h

@class WorkSession;

//! This class represents a controller to verify import/export operation
@interface VerifyWindowController : NSWindowController 
{
	@private
        WorkSession *session; //!< A work session
        SEL callback; //!< A callback to delegate after verification
        
        NSString *identifier; //!< Identifier to verify
        NSString *password; //!< Password to verify
        NSUInteger loginType; //!< login type to verify
        id delegate; //! A delegate to notifiy
}

//! Identifier for verification
@property (nonatomic, retain) NSString *identifier;
//! Password for verification
@property (nonatomic, retain) NSString *password;
//! Login type for verification
@property (nonatomic, assign) NSUInteger loginType;

//! Worksession used for verification
@property (nonatomic, retain) WorkSession *session;
//! A callback for result
@property (nonatomic, assign) SEL callback;
//! A delegate for result
@property (nonatomic, assign) id delegate;

//! Shows verfication window as sheet to window
- (void)showWindowModalToWindow:(NSWindow *)aWindow;

//! Accept UI action
- (IBAction)accept:(id)aSender;
//! Cancel UI action
- (IBAction)cancel:(id)aSender;

@end
