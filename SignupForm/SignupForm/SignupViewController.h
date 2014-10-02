//
//  SignupViewController.h
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "BZGFormViewController.h"

#import "BZGStateTextFieldCell.h"
#import "BZGMonthYearTextFieldCell.h"
#import "BZGDateTextFieldCell.h"
#import "BZGSwitchCell.h"
#import "BZGTextViewCell.h"

@class BZGMailgunEmailValidator;

@interface SignupViewController : BZGFormViewController

@property (nonatomic, strong) BZGTextFieldCell *firstName;
@property (nonatomic, strong) BZGTextFieldCell *lastName;
@property (nonatomic, strong) BZGTextFieldCell *emailCell;

@property (nonatomic, strong) BZGTextFieldCell *addressCell;
@property (nonatomic, strong) BZGTextFieldCell *cityCell;
@property (nonatomic, strong) BZGTextFieldCell *zipcodeCell;
@property (nonatomic, strong) BZGStateTextFieldCell *stateCell;

@property (nonatomic, strong) BZGPhoneTextFieldCell *phoneCell;
@property (nonatomic, strong) BZGTextFieldCell *passwordCell;

@property (nonatomic, strong) BZGMonthYearTextFieldCell *monthYearCell;
@property (nonatomic, strong) BZGDateTextFieldCell *dateCell;


@property (nonatomic, strong) BZGTextViewCell *textViewCell;


@property (nonatomic, strong) BZGSwitchCell *switchCell;

@property (nonatomic, strong) BZGMailgunEmailValidator *emailValidator;

@end
