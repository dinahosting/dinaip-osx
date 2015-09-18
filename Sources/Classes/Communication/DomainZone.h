/////////////////////////////////////////////////////////////////////////////////
//
//  DomainZone.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file DomainZone.h

/////////////////////////////////////////////////////////////////////////////////
//! This class represents domain zone structure (retrieved from a server)
@interface DomainZone : NSObject 
{
	@private
        NSString *host; //!< zone's host
        NSString *type; //!< zone type
        NSString *address; //!< zone's address
        NSXMLElement *element; //!< original XML element
        BOOL dynamic; //!< dynamic (address) flag
}

//! Provides zone's host
@property (nonatomic, retain) NSString *host;
//! Provides zone's type
@property (nonatomic, retain) NSString *type;
//! Provides zone's address
@property (nonatomic, retain) NSString *address;
//! Indicates if reciever is hidden (non editable)
@property (nonatomic, readonly) BOOL hidden;
//! Indicates if zones has IP address
@property (nonatomic, readonly) BOOL hasIPAddress;
//! Indicates if zone's address is dynamic
@property (nonatomic, assign) BOOL dynamic;
//! Indicates if reciever is valid
@property (nonatomic, assign) BOOL isValid;
//! Indicates if reciever is empty
@property (nonatomic, readonly) BOOL isEmpty;

//! Creates and initializes a domain zone object with XML element. Autoreleased.
+ (id)zoneWithXMLElement:(NSXMLElement *)anElement;
//! Initializes a domain zone object with XML element.
- (id)initWithXMLElement:(NSXMLElement *)anElement;

//! Resets a receiver to the values from initial XML element
- (void)reset;
//! Provides a dictionary representation of a receiver
- (NSDictionary *)dictionaryRepresentation;
//! Performs comparizon for sorting (default by host)
- (NSComparisonResult)compare:(DomainZone *)aDomain;
@end
