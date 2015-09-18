/////////////////////////////////////////////////////////////////////////////////
//
//  UserGetZonesDomain.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import "RPCMethod.h"

//! @file UserGetZonesDomain.h

/////////////////////////////////////////////////////////////////////////////////
//! This class represents RPC method to get domain zones
@interface UserGetZonesDomain : RPCMethod 
{
	@private
        NSString *identifier; //!< Identifier for request
        NSString *password; //!< Password for request
        NSString *domain; //!< Domain request

        NSMutableArray *domainZones; //! result zones
}
//! Identifier name
@property (nonatomic, retain) NSString *identifier;
//! Password for identifier
@property (nonatomic, retain) NSString *password;
//! Domain for zones request
@property (nonatomic, readonly) NSString *domain;
//! Retrieved zones
@property (nonatomic, readonly, retain) NSMutableArray *domainZones;
//! Editable zones
@property (nonatomic, readonly, retain) NSArray *editableZones;

//! Initializes a request method with domain name
- (id)initWithDomain:(NSString *)aDomain;

@end
