/////////////////////////////////////////////////////////////////////////////////
//
//  StatusItemController.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file StatusItemController.h

/////////////////////////////////////////////////////////////////////////////////
//! This class represents manager of application status item
@interface StatusItemController : NSObject 
{
	@private
        NSStatusItem *menuIcon; //!< UI menu icon
        NSArray *icons; //!< Icons to be used for animation of status item
        BOOL monitoring; //!< Monitoring status
        BOOL useAlernateDNS; //!< Indicates if use alternate DNS server
        NSMutableData *buffer; //!< Buffer for downloaded data
        
        NSTimer *iconTimer; //!< Timer to animate icons
        NSTimer *updateTimer; //!< Timer for IP check
        NSURLConnection *connection; //!< A connection for communication
}
//! Indicates if monitoring is in progress
@property (nonatomic, readonly) BOOL monitoring;

//! Show the status itom in UI
- (void)showStatusItem:(id)aSender;
//! Starts IP checking
- (void)startMonitoring:(id)aSender;
//! Stops IP checking
- (void)stopMonitoring:(id)aSender;
@end
