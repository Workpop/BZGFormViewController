//
//  SignupViewController.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "SignupViewController.h"
#import "BZGTextFieldCell.h"
#import "BZGPhoneTextFieldCell.h"
#import "BZGMailgunEmailValidator.h"
#import "ReactiveCocoa.h"
#import "EXTScope.h"
#import "Constants.h"

static NSString *const MAILGUN_PUBLIC_KEY = @"pubkey-501jygdalut926-6mb1ozo8ay9crlc28";

typedef NS_ENUM(NSInteger, SignupViewControllerSection) {
    SignupViewControllerSectionPrimaryInfo,
    SignupViewControllerSectionAddress,
    SignupViewControllerSectionSecondaryInfo,
    SignupViewControllerSectionSignUpButton,
    SignupViewControllerSectionCount
};

@interface SignupViewController ()

@property (strong, nonatomic) UITableViewCell *signupCell;

@end

@implementation SignupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureFirstNameCell];
    [self configureLastNameCell];

    
    [self configureEmailCell];
    
    [self configurePhoneCell];
    
    
//    [self configurePasswordCell];
    
    
    
    [self configureAddressCell];
    [self configureCityCell];
    [self configureStateCell];
    [self configureZipcodeCell];

    
    [self configureMonthYearPicker];
    [self configureDateCell];


    //basic info
    [self addFormCells:@[self.firstName, self.lastName, self.emailCell/*, self.monthYearCell*/] atSection:SignupViewControllerSectionPrimaryInfo];
    
    //address
    [self addFormCells:@[self.addressCell, self.cityCell, self.stateCell, self.zipcodeCell] atSection:SignupViewControllerSectionAddress];

    
    [self addFormCells:@[self.phoneCell, self.dateCell] atSection:SignupViewControllerSectionSecondaryInfo];
    
    
    
    self.emailValidator = [BZGMailgunEmailValidator validatorWithPublicKey:MAILGUN_PUBLIC_KEY];
    self.showsKeyboardControl = YES;
    self.title = @"BZGFormViewController";
    self.tableView.tableFooterView = [UIView new];
    
    
    //UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
   // imageView.frame = CGRectMake(0, 0, 24, 24);
   // [[BZGTextFieldCell appearance] setValidAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]]];
   
    [[BZGTextFieldCell appearance] setAccessoryImage:[UIImage imageNamed:@"checkmark"]];
    


    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    
    [self.firstName becomeFirstResponder];
}

- (void)configureFirstNameCell
{
    self.firstName = [[BZGTextFieldCell alloc] initWithFloatField];
    self.firstName.textField.placeholder = @"First Name";
    self.firstName.textField.accessibilityHint = @"This is a test hint of what we're doing. This goes here.";
    
    self.firstName.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.firstName.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        if (newText.length < 1) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"First Name must be at least 1 character."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}

- (void)configureLastNameCell
{
    self.lastName = [[BZGTextFieldCell alloc] initWithFloatField];
    self.lastName.textField.placeholder = @"Last Name";
    self.lastName.textField.accessibilityHint = @"This is a test hint of what we're doing. This goes here.";
    self.lastName.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.lastName.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        if (newText.length < 2) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"Last Name must be at least 2 characters long."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}


//second section

- (void)configureAddressCell
{
    self.addressCell = [[BZGTextFieldCell alloc] initWithFloatField];
    self.addressCell.textField.placeholder = @"Address";
    self.addressCell.textField.accessibilityHint = @"This is a test hint of what we're doing. This goes here.";
    
    self.addressCell.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.addressCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        if (newText.length < 1) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"First Name must be at least 1 character."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}

- (void)configureCityCell
{
    self.cityCell = [[BZGTextFieldCell alloc] initWithFloatField];
    self.cityCell.textField.placeholder = @"City";
    self.cityCell.textField.accessibilityHint = @"This is a test hint of what we're doing. This goes here.";
    
    self.cityCell.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.cityCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        if (newText.length < 1) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"First Name must be at least 1 character."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}


- (void)configureZipcodeCell
{
    self.zipcodeCell = [[BZGTextFieldCell alloc] initWithFloatField];
    self.zipcodeCell.textField.placeholder = @"Zip Code";
    self.zipcodeCell.textField.accessibilityHint = @"This is a test hint of what we're doing. This goes here.";
    
    self.zipcodeCell.textField.keyboardType = UIKeyboardTypeNumberPad;
    self.zipcodeCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        if (newText.length < 1) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"First Name must be at least 1 character."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}

- (void)configureStateCell
{
    self.stateCell = [[BZGStateTextFieldCell alloc] initWithFloatField];
    self.stateCell.textField.placeholder = @"State";
    self.stateCell.textField.accessibilityHint = @"What state do you live in?";
    self.stateCell.showsCheckmarkWhenValid = YES;
    self.stateCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        cell.validationState = BZGValidationStateValid;
        return YES;
    };
}



- (void)configureMonthYearPicker
{
    self.monthYearCell = [[BZGMonthYearTextFieldCell alloc] initWithFloatField];
    self.monthYearCell.textField.placeholder = @"Birthday";
    self.monthYearCell.textField.accessibilityHint = @"When is your birthday?";
    self.monthYearCell.showsCheckmarkWhenValid = YES;
    self.monthYearCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        cell.validationState = BZGValidationStateValid;
        return YES;
    };
}

- (void)configureDateCell
{
    self.dateCell = [[BZGDateTextFieldCell alloc] initWithFloatField];
    self.dateCell.textField.placeholder = @"Birth Date";
    self.dateCell.textField.accessibilityHint = @"Where should we go on what date?";
    self.dateCell.showsCheckmarkWhenValid = YES;
    self.dateCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *newText) {
        cell.validationState = BZGValidationStateValid;
        return YES;
    };
    self.dateCell.showsValidationWhileEditing = YES;
}




- (void)configureEmailCell
{
    self.emailCell = [[BZGTextFieldCell alloc] initWithFloatField];
    self.emailCell.textField.placeholder = @"Email";
    self.emailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
    @weakify(self)
    self.emailCell.didEndEditingBlock = ^(BZGTextFieldCell *cell, NSString *text) {
        @strongify(self);
        if (text.length == 0) {
            cell.validationState = BZGValidationStateNone;
            [self updateInfoCellBelowFormCell:cell];
            return;
        }
        cell.validationState = BZGValidationStateValidating;
        [self.emailValidator validateEmailAddress:self.emailCell.textField.text
                                          success:^(BOOL isValid, NSString *didYouMean) {
            if (isValid) {
                cell.validationState = BZGValidationStateValid;
            } else {
                cell.validationState = BZGValidationStateInvalid;
                [cell.infoCell setText:@"Email address is invalid."];
            }
            if (didYouMean) {
                cell.validationState = BZGValidationStateWarning;
                [cell.infoCell setText:[NSString stringWithFormat:@"Did you mean %@?", didYouMean]];
                @weakify(cell);
                @weakify(self);
                [cell.infoCell setTapGestureBlock:^{
                    @strongify(cell);
                    @strongify(self);
                    [cell.textField setText:didYouMean];
                    [self textFieldDidEndEditing:cell.textField];
                }];
            } else {
                [cell.infoCell setTapGestureBlock:nil];
            }
            [self updateInfoCellBelowFormCell:cell];
        } failure:^(NSError *error) {
            cell.validationState = BZGValidationStateNone;
            [self updateInfoCellBelowFormCell:cell];
        }];
    };
}

- (void)configurePhoneCell
{
    self.phoneCell = [[BZGPhoneTextFieldCell alloc] initWithFloatField];
    self.phoneCell.textField.placeholder = @"Phone Number";
}

- (void)configurePasswordCell
{
    self.passwordCell = [BZGTextFieldCell new];
    self.passwordCell.label.text = @"Password";
    self.passwordCell.textField.placeholder = @"••••••••";
    self.passwordCell.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.passwordCell.textField.secureTextEntry = YES;
    self.passwordCell.shouldChangeTextBlock = ^BOOL(BZGTextFieldCell *cell, NSString *text) {
        cell.validationState = BZGValidationStateNone;
        if (text.length < 8) {
            cell.validationState = BZGValidationStateInvalid;
            [cell.infoCell setText:@"Password must be at least 8 characters long."];
        } else {
            cell.validationState = BZGValidationStateValid;
        }
        return YES;
    };
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SignupViewControllerSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SignupViewControllerSectionSignUpButton) {
        return 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SignupViewControllerSectionSignUpButton) {
        return self.signupCell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)signupCell
{
    UITableViewCell *cell = _signupCell;
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = @"Sign Up";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        RAC(cell, selectionStyle) =
        [RACObserve(self, isValid) map:^NSNumber *(NSNumber *isValid) {
            return isValid.boolValue ? @(UITableViewCellSelectionStyleDefault) : @(UITableViewCellSelectionStyleNone);
        }];

        RAC(cell.textLabel, textColor) =
        [RACObserve(self, isValid) map:^UIColor *(NSNumber *isValid) {
            return isValid.boolValue ? BZG_BLUE_COLOR : [UIColor lightGrayColor];
        }];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SignupViewControllerSectionSignUpButton) {
        return 44;
    }
    else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == SignupViewControllerSectionSecondaryInfo) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
        label.text = @"Secondary Info";
        label.textAlignment = NSTextAlignmentCenter;
        return label;
    }
    else if (section == SignupViewControllerSectionAddress) {
        UIView *label = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
        label.backgroundColor = [UIColor clearColor];
        return label;
    }
    else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SignupViewControllerSectionSecondaryInfo) {
        return 30;
    }
    if (section == SignupViewControllerSectionAddress) {
        return 30;
    }
    else {
        return CGFLOAT_MIN;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

@end
