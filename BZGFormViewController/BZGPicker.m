//
//  Created by Seth Sandler on 8/6/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//

#import "BZGPicker.h"

@interface BZGPicker () <UIPickerViewDelegate, UIPickerViewDataSource>
@end

@implementation BZGPicker

- (void)setup
{
    [super setDataSource:self];
    [super setDelegate:self];

    [self setShowsSelectionIndicator:YES];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

- (void)setSelectedOption:(NSString *)option animated:(BOOL)animated
{
    NSInteger index = [self.options indexOfObject:option];
    if (index != NSNotFound)
    {
        [self selectRow:index inComponent:0 animated:animated];
    }
}

- (void)setSelectedOption:(NSString *)option
{
    [self setSelectedOption:option animated:NO];
}

- (NSString *)selectedName
{
    NSInteger index = [self selectedRowInComponent:0];
    return self.options[index];
}

#pragma mark -
#pragma mark UIPicker

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component
{
    return [self.options count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.options objectAtIndex:row];
}

- (void)pickerView:(__unused UIPickerView *)pickerView
      didSelectRow:(__unused NSInteger)row
       inComponent:(__unused NSInteger)component
{
    if ([self.pickerDelegate respondsToSelector:@selector(picker:didSelectOption:)]) {
        [self.pickerDelegate picker:self didSelectOption:[self.options objectAtIndex:row]];
    }
}

@end
