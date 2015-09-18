/////////////////////////////////////////////////////////////////////////////////
//
//  MainWindowController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file MainWindowController.h

/////////////////////////////////////////////////////////////////////////////////
@class LoginWindowController;
@class AddDomainWindowController;
@class VerifyWindowController;
@class WorkSession;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents (description)
@interface MainWindowController : NSWindowController 
{
	@private
    	NSTableView *domainTable; //!< UI table view
        LoginWindowController *loginController; //!< login controller
        VerifyWindowController *verifyController; //!< verify controller
        AddDomainWindowController *addController; //!< add domain controller
        
        WorkSession *session; //!< current working session
        NSMutableArray *domains; //!< retrieved (all) domains
        NSMutableDictionary *editingDomains; //!< opened zone's windows
        BOOL justLaunched; //!< a first start flag
}
//! UI table
@property (nonatomic, assign) IBOutlet NSTableView *domainTable;
//! Current work session
@property (nonatomic, retain) WorkSession *session;

//! UI action initiating login
- (IBAction)login:(id)aSender;

//! UI action initiating add domain
- (IBAction)addDomain:(id)aSender;
//! UI action initiating edit domain
- (IBAction)editDomain:(id)aSender;
//! UI action initiating delete domain
- (IBAction)deleteDomain:(id)aSender;

//! UI action initiating export application configuration
- (IBAction)exportConfiguration:(id)aSender;
//! UI action initiating import application configuration
- (IBAction)importConfiguration:(id)aSender;

//! Brings receivers' window to screen with ready login
- (void)showWithLoginController:(LoginWindowController *)aController;
//! Just activates the controller
- (void)setupWithoutWindow;
@end
