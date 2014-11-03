//
//  BZGStatePicker.h
//
//  Created by Seth Sandler on 8/6/14.
//  Copyright (c) 2014 Benjamin Berman. All rights reserved.
//


#import <Availability.h>
#import <UIKit/UIKit.h>

@class BZGStatePicker;

@protocol BZGStatePickerDelegate <NSObject>

- (void)statePicker:(BZGStatePicker *)picker didSelectStateWithName:(NSString *)name;

@end


@interface BZGStatePicker : UIPickerView

@property (nonatomic, weak) id<BZGStatePickerDelegate> stateDelegate;
@property (nonatomic, copy) NSString *selectedStateName;

- (void)setSelectedStateName:(NSString *)stateName animated:(BOOL)animated;

- (void)setSelectedStateNameFromStateCode:(NSString *)stateCode animated:(BOOL)animated;


@end