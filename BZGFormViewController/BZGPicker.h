//
//  BZGStatePicker.h
//
//  Created by Seth Sandler on 8/6/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//


#import <Availability.h>
#import <UIKit/UIKit.h>

@class BZGPicker;

@protocol BZGPickerDelegate <NSObject>

- (void)picker:(BZGPicker *)picker didSelectOption:(NSString *)name;

@end


@interface BZGPicker : UIPickerView

@property (nonatomic, copy) NSString *selectedName;
@property (nonatomic, strong) NSArray *options;

@property (nonatomic, weak) id<BZGPickerDelegate> pickerDelegate;

- (void)setSelectedOption:(NSString *)option animated:(BOOL)animated;

@end