//
//  BZGSwitchCell.h
//  Pods
//
//  Created by Seth Sandler on 10/1/14.
//
//

#import "BZGFormCell.h"

@interface BZGSwitchCell : BZGFormCell

@property (strong, nonatomic) UILabel *label;

@property (strong, nonatomic) UISwitch *switchField;

/// The color of the text field's text when the cell's state is not invalid.
@property (strong, nonatomic) UIColor *textFieldNormalColor;

/// The color of the text field's text when the cell's state is invalid.
@property (strong, nonatomic) UIColor *textFieldInvalidColor;

/// The block called when the text field's text ends editing.
@property (copy, nonatomic) void (^didEndEditingBlock)(BZGSwitchCell *cell, NSString *text);

@end