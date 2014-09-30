//
//  Created by Seth Sandler on 8/6/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//

#import "BZGMonthYearTextFieldCell.h"

@implementation BZGMonthYearTextFieldCell

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
    self.datePicker = [[BZGMonthYearPicker alloc] init];
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:-(622080000)]; //default to 20 years ago
    
    //self.datePicker.maximumDate = [NSDate date];
    //self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    self.datePicker._delegate = self;
    
    self.textField.inputView = self.datePicker;
}

-(void)pickerView:(UIPickerView *)pickerView didChangeDate:(NSDate *)newDate
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSCalendarUnitDay;
    NSDateComponents* components = [calendar components:unitFlags fromDate:newDate];
    NSString *dateString = [NSString stringWithFormat:@"%02ld/%li", (long)[components month], (long)[components year]];
    self.textField.text = dateString;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
    [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
}

@end