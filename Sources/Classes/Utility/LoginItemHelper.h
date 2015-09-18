/////////////////////////////////////////////////////////////////////////////////
//
//  LoginItemHelper.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file LoginItemHelper.h

/////////////////////////////////////////////////////////////////////////////////
//! A notification posted whenever login item state is changed externally
extern NSString *const kLoginItemStatusDidChange;

//! This class represents wrapper around LoginItem in system LoginItems list
//! and allows to add/remove a holding URL to/from a list, as well as to
//! monitor changes in the list and notifies about updates.
@interface LoginItemHelper : NSObject 
{
	@private
    	NSURL *itemURL; //!< A URL of application
        uint32_t identifier; //!< ID of login item
        LSSharedFileListRef sharedList; //!< Login items list
}
//! Indicates if receiver is present in Login items
@property (nonatomic, readonly) BOOL isInstalled;
//! Provide receiver's identifier (0 if not installed)
@property (nonatomic, readonly) uint32_t identifier;

//! Initializes the class with item URL and identifier. Designated initializer.
//! anItemURL is required. anID is optional.
- (id)initWithURL:(NSURL *)anItemURL identifier:(uint32_t)anID;

//! Adds receiver's URL into Login items
- (void)install:(id)aSender;

//! Removes receiver's URL from Login items
- (void)uninstall:(id)aSender;
@end
