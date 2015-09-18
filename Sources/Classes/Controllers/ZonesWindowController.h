/////////////////////////////////////////////////////////////////////////////////
//
//  ZonesWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file ZonesWindowController.h

/////////////////////////////////////////////////////////////////////////////////
@class UserGetZonesDomain;
@class RPCMethod;
@class ZonesWindowController;
@class WorkSession;

extern NSString *const kZoneEditDidFinishNotification;

/////////////////////////////////////////////////////////////////////////////////
//! Zones Edit Window delegate
@protocol ZonesWindowControllerDelegate<NSObject>
@optional
//! Called when zones did finish udpating
- (void)zoneEditControllerDidFinish:(ZonesWindowController *)aController;
@end

/////////////////////////////////////////////////////////////////////////////////
//! This class represents a zones edit window controller
@interface ZonesWindowController : NSWindowController 
{
	@private
        id<ZonesWindowControllerDelegate> delegate; //!< A delegate of controller
        NSWindow *owner; //!< A main window
        
        IBOutlet NSWindow *progressPane; //!< A progress window
        IBOutlet NSProgressIndicator *spinner; //!< A progress indicator
        IBOutlet NSTextField *status; //!< A progress status
        IBOutlet NSTableView *zonesTable; //!< A zones UI table
        
        UserGetZonesDomain *lastMethod; //!< A get zones last method
        RPCMethod *executedMethod; //!< A get zones last method
       	NSMutableDictionary *reusedCells; //!< reused custom option cells
        NSString *domain; //!< A domain name
		WorkSession *session; //!< A work session 
        BOOL isModified; //!< A modified flag
        BOOL shouldDetectDynamicIP; //!< A autodetecting flag
}

//! A delegate object
@property (nonatomic, assign) id<ZonesWindowControllerDelegate> delegate;
//! Indicates if IP autodetecting activated
@property (nonatomic, assign) BOOL shouldDetectDynamicIP;
//! A edited domain
@property (nonatomic, retain) NSString *domain;
//! A work session
@property (nonatomic, retain) WorkSession *session;
//! Presents zones edit window
- (void)showWindowModalToWindow:(NSWindow *)aWindow;

//! Save UI action
- (IBAction)saveChanges:(id)aSender;
//! Cancel zones editing
- (IBAction)cancel:(id)aSender;
//! Cancel progress window
- (IBAction)cancelProgress:(id)aSender;
@end
