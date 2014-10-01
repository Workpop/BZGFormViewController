//
//  BZGDateTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "BZGDateTextFieldCell.h"

@implementation BZGDateTextFieldCell

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
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.maximumDate = [NSDate date];
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:-(622080000)]; //default to 20 years ago
    [self.datePicker addTarget:self action:@selector(dateDidChange) forControlEvents:UIControlEventValueChanged];
    
    self.textField.inputView = self.datePicker;
}

- (void)dateDidChange
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSCalendarUnitDay;
    NSDateComponents* components = [calendar components:unitFlags fromDate:self.datePicker.date];
    NSString *dateString = [NSString stringWithFormat:@"%02ld/%02ld/%li", (long)[components month], (long)[components day], (long)[components year]];
    [self.textField setText:dateString];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
    [self.textField sendActionsForControlEvents:UIControlEventEditingChanged];
}


@end
