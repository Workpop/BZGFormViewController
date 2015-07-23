//
//  BZGStateTextFieldCell.m
//  SignupForm
//
//  Created by Seth Sandler on 9/29/14.
//  Copyright (c) 2014 benzguo. All rights reserved.
//

#import "BZGPickerTextFieldCell.h"

@implementation BZGPickerTextFieldCell

-(id)initWithFloatField
{
    self = [super initWithFloatField];
    if (self) {
        [self setupCell];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupCell];
    }
    return self;
}

-(void)setupCell
{
    //use statePicker for state input
    self.picker = [[BZGPicker alloc] initWithFrame:CGRectMake(0, 0, 0, 250)];
    self.picker.pickerDelegate = self;
    self.textField.inputView = self.picker;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:self.textField];
}

-(void)picker:(BZGPicker *)picker didSelectOption:(NSString *)option
{
    [self setText:option];
}

-(void)setOptions:(NSArray*)options
{
    self.picker.options = options;
    [self.picker reloadAllComponents];
}

//This selects the right picker option
- (void)textFieldChanged:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([textField isEqual:self.textField]) {
        
        //insert programType
        if (self.textField.text.length > 0){
            [self.picker setSelectedOption:self.textField.text animated:NO];
        }
    }
}

@end