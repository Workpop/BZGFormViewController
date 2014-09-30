//
//  BZGStateTextFieldCell.h
//  SignupForm
//
//  Created by Seth Sandler on 9/29/14.
//  Copyright (c) 2014 benzguo. All rights reserved.
//

#import "BZGTextFieldCell.h"
#import "BZGStatePicker.h"

@interface BZGStateTextFieldCell : BZGTextFieldCell <BZGStatePickerDelegate>

/// The text to display in the info cell when the phone number is invalid
@property (strong, nonatomic) NSString *invalidText;
@property (strong, nonatomic) BZGStatePicker *statePicker;

@end