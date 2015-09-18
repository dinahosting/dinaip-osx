/////////////////////////////////////////////////////////////////////////////////
//
//  AddDomainWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file AddDomainWindowController.h

/////////////////////////////////////////////////////////////////////////////////
//! A protocol to be implelemtned by an object wanted to receive callbacks from
//! a AddDomainWindowController
@protocol AddDomainWindowControllerDelegate<NSObject>
@optional
//! Sent to a delegate whenever and user clicks OK in a Add Domain window
- (void)addDomainControllerDidSelectDomain:(NSString *)aDomain;
@end

/////////////////////////////////////////////////////////////////////////////////
//! This class represents Add Domain window manager
@interface AddDomainWindowController : NSWindowController 
{
	@private
        id delegate; //!< A delegate object
        BOOL isManual; //!< A manual entrance flag
        NSString *selectedDomain; //!< A selected domain
        NSArray *availableDomains; //!< All domains
}

//! A receiver's delegate object
@property (nonatomic, assign) id delegate;
//! Indicates if domain entered manualy
@property (nonatomic, assign) BOOL isManual;
//! User selected domain
@property (nonatomic, retain) NSString *selectedDomain;
//! All available domains
@property (nonatomic, retain) NSArray *availableDomains;

//! Shows receiver's window as sheet to provided window
- (void)showWindowModalToWindow:(NSWindow *)aWindow;

//! Called on Accept button clicked
- (IBAction)accept:(id)aSender;
//! Called on Cancel button clicked
- (IBAction)cancel:(id)aSender;
//! Called on Change entrance radio button clicked
- (IBAction)changeMode:(id)aSender;
@end
