/////////////////////////////////////////////////////////////////////////////////
//
//  OptionTableCell.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file OptionTableCell.h

/////////////////////////////////////////////////////////////////////////////////
//! This class represents custom cell element for zone edit table, showing buttons
//! and a check box
@interface OptionTableCell : NSActionCell 
{
	@private
    	NSButtonCell *switchButton; //!< checkbox
        NSButtonCell *removeButton; //!< delete button
        NSButtonCell *addButton; //!< add button
        BOOL shouldShowAddButton; //!< a flag for add button visibility
        BOOL shouldShowSwitchButton; //!< a flag for checkbox visibility
}

//! Indicates if add button shown
@property (nonatomic, assign) BOOL shouldShowAddButton;
//! Indicates if checkbox shown
@property (nonatomic, assign) BOOL shouldShowSwitchButton;

//! Assigns action for Add button
- (void)setAddAction:(SEL)anAction target:(id)aTarget;
//! Assigns action for Remove button
- (void)setRemoveAction:(SEL)anAction target:(id)aTarget;
//! Assigns action for checkbox
- (void)setSwitchAction:(SEL)anAction target:(id)aTarget;

@end
