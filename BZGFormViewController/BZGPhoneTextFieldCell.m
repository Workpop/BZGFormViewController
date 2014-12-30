//
//  BZGPhoneTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "BZGPhoneTextFieldCell.h"
#import "NSError+BZGFormViewController.h"

#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

@interface BZGPhoneTextFieldCell ()

// Phone number formatting
@property (strong, nonatomic) NBAsYouTypeFormatter *phoneFormatter;
@property (strong, nonatomic) NSString *regionCode;
@property (strong, nonatomic) NBPhoneNumberUtil *phoneUtil;

@end

@implementation BZGPhoneTextFieldCell

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
    NSLocale *locale = [NSLocale currentLocale];
    self.regionCode = [[locale localeIdentifier] substringFromIndex:3];
    self.phoneFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:self.regionCode];
    self.phoneUtil = [NBPhoneNumberUtil sharedInstance];
    self.invalidText = @"Please enter a valid phone number";
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
}

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    // Disable long press
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) 
    {
        gestureRecognizer.enabled = NO;
    }
    [super addGestureRecognizer:gestureRecognizer];
    return;
}

-(void)setText:(NSString *)string
{
    NSCharacterSet *digitSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    // Set number
    if (string.length > 0 &&
        [string rangeOfCharacterFromSet:digitSet].length != 0 &&
        NSMakeRange(0, string.length).location == self.textField.text.length) {
        self.textField.text = [self.phoneFormatter inputDigit:string];
    }
    
    // validate
    [self validatePhoneNumber:self.textField.text];

    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
}

- (BOOL)shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger length = [self getLength:self.textField.text];
    
    if(length == 10)
    {
        if(range.length == 0)
        {
            if (string.length == 0) {
                self.validationState = BZGValidationStateInvalid;
                self.validationError = [NSError bzg_errorWithDescription:self.invalidText];
            }
            else{
                [self validatePhoneNumber:self.textField.text];
            }
            return NO;
        }
    }
    
    if(length == 3)
    {
        NSString *num = [self formatNumber:self.textField.text];
        self.textField.text = [NSString stringWithFormat:@"(%@) ",num];
        if(range.length > 0)
            self.textField.text = [NSString stringWithFormat:@"%@",[num substringToIndex:3]];
    }
    else if(length == 6)
    {
        NSString *num = [self formatNumber:self.textField.text];
        self.textField.text = [NSString stringWithFormat:@"(%@) %@-",[num  substringToIndex:3],[num substringFromIndex:3]];
        if(range.length > 0)
            self.textField.text = [NSString stringWithFormat:@"(%@) %@",[num substringToIndex:3],[num substringFromIndex:3]];
    }
    
    if (string.length == 0) {
        self.validationState = BZGValidationStateInvalid;
        self.validationError = [NSError bzg_errorWithDescription:self.invalidText];
    }
    else{
        [self validatePhoneNumber:[self.textField.text stringByAppendingString:string]];
    }
    
    return YES;
}


- (void)validatePhoneNumber:(NSString*)string
{
    // Validate text
    NSError *error = nil;
    NBPhoneNumber *phoneNumber = [self.phoneUtil parse:string
                                         defaultRegion:self.regionCode
                                                 error:&error];
    if (!error) {
        BOOL isPossibleNumber = NO;
        if ([self.regionCode isEqualToString:@"US"]) {
            // Don't allow 7-digit local format
            NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
            NSString *strippedPhoneString = [[string componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            isPossibleNumber = [self.phoneUtil isPossibleNumber:phoneNumber error:&error] && strippedPhoneString.length >= 10;
        }
        else {
            isPossibleNumber = [self.phoneUtil isPossibleNumber:phoneNumber error:&error];
        }
        if (error || !isPossibleNumber) {
            self.validationState = BZGValidationStateInvalid;
            self.validationError = [NSError bzg_errorWithDescription:self.invalidText];
        } else {
            self.validationState = BZGValidationStateValid;
            self.validationError = nil;
        }
    }
    else {
        self.validationState = BZGValidationStateInvalid;
        self.validationError = [NSError bzg_errorWithDescription:self.invalidText];
    }
}


-(NSString*)formatNumber:(NSString*)mobileNumber
{
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    NSUInteger length = [mobileNumber length];
    if(length > 10)
    {
        mobileNumber = [mobileNumber substringFromIndex: length-10];
    }
    
    return mobileNumber;
}


-(NSUInteger)getLength:(NSString*)mobileNumber
{
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    NSUInteger length = [mobileNumber length];
    return length;
}

@end
