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
}

-(void)statePicker:(BZGStatePicker *)picker didSelectStateWithName:(NSString *)name
{
    self.textField.text = name;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
    [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
}

@end