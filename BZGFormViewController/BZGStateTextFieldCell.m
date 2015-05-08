//
//  BZGStateTextFieldCell.m
//  SignupForm
//
//  Created by Seth Sandler on 9/29/14.
//  Copyright (c) 2014 benzguo. All rights reserved.
//

#import "BZGStateTextFieldCell.h"

@implementation BZGStateTextFieldCell

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
    self.statePicker = [[BZGStatePicker alloc] initWithFrame:CGRectMake(0, 0, 0, 250)];
    self.statePicker.stateDelegate = self;
    self.textField.inputView = self.statePicker;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:self.textField];
}

-(void)statePicker:(BZGStatePicker *)picker didSelectStateWithName:(NSString *)name
{
    [self setText:name];
}

//This selects the right picker option
- (void)textFieldChanged:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([textField isEqual:self.textField]) {
        
        //insert programType
        if (self.textField.text.length > 0){
            [self.statePicker setSelectedStateNameFromStateCode:self.textField.text animated:NO];
        }
    }
}


@end