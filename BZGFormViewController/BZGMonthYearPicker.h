//
//  BZGMonthYearPicker.h
//  Workpop-iOS
//
//  Created by Seth Sandler on 9/2/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIMonthYearPickerValueChangeBlock)(NSDate *newDate);

@protocol BZGMonthYearPickerDelegate

@optional
- (void) pickerView:(UIPickerView *)pickerView didChangeDate:(NSDate *)newDate;
@end

@interface BZGMonthYearPicker : UIPickerView <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) id _delegate;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) NSDate * minimumDate;
@property (nonatomic, strong) NSDate * maximumDate;

- (void) selectToday;

@end