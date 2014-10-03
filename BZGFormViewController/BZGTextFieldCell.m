//
//  BZGTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>

#import "BZGTextFieldCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@interface BZGTextFieldCell ()
/// Whether to use a float textfield or label and textfield
@property (assign, nonatomic) BOOL isFloatField;
@end

@implementation BZGTextFieldCell

- (id)initWithFloatField
{
    self = [super init];
    if (self) {
        self.isFloatField = YES;
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.isFloatField = NO;
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.showsCheckmarkWhenValid = YES;
    self.showsValidationWhileEditing = NO;
    self.infoCell = [[BZGInfoCell alloc] init];

    [self configureActivityIndicatorView];
    
    if (!_isFloatField) {
        [self configureLabel];
    }
    [self configureTextField];
    
    [self configureTap];
    [self configureBindings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldTextDidEndEditing:)
                                                 name:UITextFieldTextDidEndEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
}

-(void)layoutSubviews
{
    
    [super layoutSubviews];
    
    if (self.textField) {
        CGRect rect = self.textField.frame;
        rect.size.height = self.bounds.size.height;
        self.textField.frame = rect;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureTextField
{
    CGFloat textFieldY = 0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        textFieldY = 12;
    }
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    if (self.isFloatField) {
        CGFloat textFieldX = self.separatorInset.left;
        CGRect textFieldFrame = CGRectMake(textFieldX,
                                           textFieldY,
                                           self.bounds.size.width - textFieldX - self.activityIndicatorView.frame.size.width,
                                           self.bounds.size.height);
        self.textField = [[JVFloatLabeledTextField alloc] initWithFrame:textFieldFrame];
        ((JVFloatLabeledTextField*)self.textField).floatingLabelYPadding = 5;
    }
    else{
        CGFloat textFieldX = self.bounds.size.width * 0.35;
        CGRect textFieldFrame = CGRectMake(textFieldX,
                                           textFieldY,
                                           self.bounds.size.width - textFieldX - self.activityIndicatorView.frame.size.width,
                                           self.bounds.size.height);
        self.textField = [[UITextField alloc] initWithFrame:textFieldFrame];
    }
    
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textFieldNormalColor = BZG_TEXTFIELD_NORMAL_COLOR;
    self.textFieldInvalidColor = BZG_TEXTFIELD_INVALID_COLOR;
    self.textField.font = BZG_TEXTFIELD_FONT;
    self.textField.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textField];
}

- (void)configureLabel
{
    CGFloat labelX = 10;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        labelX = 15;
    }
    CGRect labelFrame = CGRectMake(labelX,
                                   0,
                                   self.textField.frame.origin.x - labelX,
                                   self.bounds.size.height);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    self.label.font = BZG_TEXTFIELD_LABEL_FONT;
    self.label.textColor = BZG_TEXTFIELD_LABEL_COLOR;
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
}

- (void)configureActivityIndicatorView
{
    CGFloat activityIndicatorWidth = self.bounds.size.height*0.7;
    CGRect activityIndicatorFrame = CGRectMake(self.bounds.size.width - activityIndicatorWidth,
                                               0,
                                               activityIndicatorWidth,
                                               self.bounds.size.height);
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicatorView setFrame:activityIndicatorFrame];
    self.activityIndicatorView.hidesWhenStopped = NO;
    self.activityIndicatorView.hidden = YES;
    [self addSubview:self.activityIndicatorView];
}

- (void)configureTap {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)];
    [self.contentView addGestureRecognizer:tap];
}

- (void)configureBindings
{
    @weakify(self);

    RAC(self.textField, textColor) =
    [RACObserve(self, validationState) map:^UIColor *(NSNumber *validationState) {
        @strongify(self);
        if (self.textField.editing &&
            !self.showsValidationWhileEditing) {
            return self.textFieldNormalColor;
        }
        switch (validationState.integerValue) {
            case BZGValidationStateInvalid:
                return self.textFieldInvalidColor;
                break;
            case BZGValidationStateValid:
            case BZGValidationStateValidating:
            case BZGValidationStateWarning:
            case BZGValidationStateNone:
            default:
                return self.textFieldNormalColor;
                break;
        }
    }];

    RAC(self.activityIndicatorView, hidden) =
    [RACObserve(self, validationState) map:^NSNumber *(NSNumber *validationState) {
        @strongify(self);
        if (validationState.integerValue == BZGValidationStateValidating) {
            [self.activityIndicatorView startAnimating];
            return @NO;
        } else {
            [self.activityIndicatorView stopAnimating];
            return @YES;
        }
    }];

    RAC(self, accessoryType) =
    [RACObserve(self, validationState) map:^NSNumber *(NSNumber *validationState) {
        @strongify(self);
        if (validationState.integerValue == BZGValidationStateValid &&
            (!self.textField.editing || self.showsValidationWhileEditing) &&
            self.showsCheckmarkWhenValid) {

            if (self.accessoryImage) {
                [self setAccessoryViewImage:self.accessoryImage];
                return @(UITableViewCellAccessoryNone);
            }
            
            return @(UITableViewCellAccessoryCheckmark);
        } else {

            if (self.accessoryImage) {
                self.accessoryView = nil;
            }
            
            return @(UITableViewCellAccessoryNone);
        }
    }];
}

+ (BZGTextFieldCell *)parentCellForTextField:(UITextField *)textField
{
    UIView *view = textField;
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGTextFieldCell class]]) break;
    }
    return (BZGTextFieldCell *)view;
}

- (void)setShowsCheckmarkWhenValid:(BOOL)showsCheckmarkWhenValid
{
    _showsCheckmarkWhenValid = showsCheckmarkWhenValid;
    // Force RACObserve to trigger
    self.validationState = self.validationState;
}

-(void)setFloatingLabelYPadding:(CGFloat)floatingLabelYPadding
{
    if ([self.textField isKindOfClass:[JVFloatLabeledTextField class]]) {
        ((JVFloatLabeledTextField*)self.textField).floatingLabelYPadding = floatingLabelYPadding;
    }
}


- (void)setAccessoryViewImage:(UIImage *)image {
    
    self.accessoryView = [[UIImageView alloc] initWithImage:image];
    self.accessoryView.frame = CGRectMake(0, 0, 24, 24);
}

-(void)setAccessoryImage:(UIImage *)accessoryImage
{
    _accessoryImage = accessoryImage;
    
    if (self.validationState == BZGValidationStateValid) {
        [self setAccessoryViewImage:_accessoryImage];
    }
}


#pragma mark - UITextField notification selectors
// I'm using these notifications to flush the validation state signal.
// It works, but seems hacky. Is there a better way?

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([textField isEqual:self.textField]) {
        self.validationState = self.validationState;
        
        // Secure text fields clear on begin editing on iOS6+.
        // If it seems like the text field has been cleared,
        // invoke the text change delegate method again to ensure proper validation.
        if (textField.secureTextEntry && textField.text.length <= 1) {
            [self.textField.delegate textField:self.textField
                 shouldChangeCharactersInRange:NSMakeRange(0, textField.text.length)
                             replacementString:textField.text];
        }
        
        // PickerViews require forwarding the event to shouldchangeCharactersInRange
        if ([textField.inputView isKindOfClass:[UIPickerView class]] ||
            [textField.inputView isKindOfClass:[UIDatePicker class]]) {
            [self.textField.delegate textField:self.textField
                 shouldChangeCharactersInRange:NSMakeRange(0, textField.text.length)
                             replacementString:textField.text];
        }
    }
}

-(void)setText:(NSString *)text
{
    self.textField.text = text;
    
    [self.textField.delegate textField:self.textField
         shouldChangeCharactersInRange:NSMakeRange(0, self.textField.text.length)
                     replacementString:self.textField.text];

    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
}

- (void)textFieldTextDidEndEditing:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([textField isEqual:self.textField]) {
        self.validationState = self.validationState;
    }
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.textField resignFirstResponder];
}

@end
