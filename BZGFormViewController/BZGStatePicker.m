//
//  Created by Seth Sandler on 8/6/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//

#import "BZGStatePicker.h"

@interface BZGStatePicker () <UIPickerViewDelegate, UIPickerViewDataSource>
@end

@implementation BZGStatePicker

/* A static array of stateNames */
+ (NSArray *)stateNames
{
    static NSArray *_stateNames = nil;
    if (!_stateNames)
    {
        _stateNames = [[NSArray alloc] initWithObjects:@"(International)", @"Alabama", @"Alaska", @"Arizona", @"Arkansas", @"California", @"Colorado", @"Connecticut", @"Delaware", @"Florida", @"Georgia", @"Hawaii", @"Idaho", @"Illinois", @"Indiana", @"Iowa", @"Kansas", @"Kentucky", @"Louisiana", @"Maine", @"Maryland", @"Massachusetts", @"Michigan", @"Minnesota", @"Mississippi", @"Missouri", @"Montana", @"Nebraska", @"Nevada", @"New Hampshire", @"New Jersey", @"New Mexico", @"New York", @"North Carolina", @"North Dakota", @"Ohio", @"Oklahoma", @"Oregon", @"Pennsylvania", @"Rhode Island", @"South Carolina", @"South Dakota", @"Tennessee", @"Texas", @"Utah", @"Vermont", @"Virginia", @"Washington", @"West Virginia", @"Wisconsin", @"Wyoming", nil];
    }
    return _stateNames;
}

+ (NSArray *)stateCodes
{
    static NSArray *_stateCodes = nil;
    if (!_stateCodes)
    {
        _stateCodes = [[NSArray alloc] initWithObjects:@"XX", @"AL", @"AK", @"AZ", @"AR", @"CA", @"CO", @"CT", @"DE", @"FL", @"GA", @"HI", @"ID", @"IL", @"IN", @"IA", @"KS", @"KY", @"LA", @"ME", @"MD", @"MA", @"MI", @"MN", @"MS", @"MO", @"MT", @"NE", @"NV", @"NH", @"NJ", @"NM", @"NY", @"NC", @"ND", @"OH", @"OK", @"OR", @"PA", @"RI", @"SC", @"SD", @"TN", @"TX", @"UT", @"VT", @"VA", @"WA", @"WV", @"WI", @"WY", nil];
    }
    return _stateCodes;
}



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

- (void)setSelectedStateName:(NSString *)stateName animated:(BOOL)animated
{
    NSInteger index = [[[self class] stateNames] indexOfObject:stateName];
    if (index != NSNotFound)
    {
        [self selectRow:index inComponent:0 animated:animated];
    }
}

- (void)setSelectedStateNameFromStateCode:(NSString *)stateCode animated:(BOOL)animated
{
    NSUInteger index = [[[self class] stateCodes] indexOfObject:stateCode];
    NSString * stateName = [[[self class] stateNames] objectAtIndex:index];
    [self setSelectedStateName:stateName animated:animated];
}

- (void)setSelectedstateName:(NSString *)stateName
{
    [self setSelectedStateName:stateName animated:NO];
}

- (NSString *)selectedStateName
{
    NSInteger index = [self selectedRowInComponent:0];
    return [[self class] stateNames][index];
}

#pragma mark -
#pragma mark UIPicker

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component
{
    return [[[self class] stateNames] count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[[self class] stateNames] objectAtIndex:row];
}

- (void)pickerView:(__unused UIPickerView *)pickerView
      didSelectRow:(__unused NSInteger)row
       inComponent:(__unused NSInteger)component
{
    if ([self.stateDelegate respondsToSelector:@selector(statePicker:didSelectStateWithName:)]) {
        NSUInteger index = [[[self class] stateNames] indexOfObject:self.selectedStateName];
        NSString * stateCode = [[[self class] stateCodes] objectAtIndex:index];
        [self.stateDelegate statePicker:self didSelectStateWithName:stateCode];
    }
}

@end
