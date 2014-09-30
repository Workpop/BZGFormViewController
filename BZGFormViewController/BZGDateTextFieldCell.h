//
//  BZGDateTextFieldCell.h
//

#import "BZGTextFieldCell.h"

@interface BZGDateTextFieldCell : BZGTextFieldCell

/// The text to display in the info cell when the phone number is invalid
@property (strong, nonatomic) NSString *invalidText;

@property (strong, nonatomic) UIDatePicker *datePicker;

@end
