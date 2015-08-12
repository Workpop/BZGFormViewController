//
//  BZGTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>

#import "BZGTextViewCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@interface BZGTextViewCell () <UITextViewDelegate>
/// Whether to use a float textfield or label and textfield
@property (assign, nonatomic) BOOL isFloatField;
@end

@implementation BZGTextViewCell

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
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldTextDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
    
    self.contentView.backgroundColor = [UIColor clearColor];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect textViewFrame = self.textField.frame;
    textViewFrame.origin.x = self.separatorInset.left;
    textViewFrame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    textViewFrame.size.width = self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
    CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
    CGFloat height = ceilf(textViewSize.height);
    height =  height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
    textViewFrame.size.height =  height;
    if (![self.textLabel.text length])
    {
        textViewFrame.origin.y = self.textLabel.frame.origin.y;
    }
    self.textField.frame = textViewFrame;
    
    textViewFrame.origin.x += 5;
    textViewFrame.size.width -= 5;
    self.detailTextLabel.frame = textViewFrame;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.height = self.textField.frame.origin.y + self.textField.frame.size.height + 15;
    self.contentView.frame = contentViewFrame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureTextField
{
    CGFloat textFieldY = 0;
    if (self.isFloatField) {
        CGFloat textFieldX = self.separatorInset.left;
        CGRect textFieldFrame = CGRectMake(textFieldX,
                                           textFieldY,
                                           self.bounds.size.width - textFieldX - self.activityIndicatorView.frame.size.width,
                                           self.bounds.size.height);
        self.textField = [[JVFloatLabeledTextView alloc] initWithFrame:textFieldFrame];
        ((JVFloatLabeledTextView*)self.textField).floatingLabelYPadding = 5;
        ((JVFloatLabeledTextView*)self.textField).scrollEnabled = NO;
    }
    else{
        CGFloat textFieldX = self.bounds.size.width * 0.35;
        CGRect textFieldFrame = CGRectMake(textFieldX,
                                           textFieldY,
                                           self.bounds.size.width - textFieldX - self.activityIndicatorView.frame.size.width,
                                           self.bounds.size.height);
        self.textField = [[UITextView alloc] initWithFrame:textFieldFrame];
    }
    
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textFieldNormalColor = BZG_TEXTFIELD_NORMAL_COLOR;
    self.textFieldInvalidColor = BZG_TEXTFIELD_INVALID_COLOR;
    self.textField.font = BZG_TEXTFIELD_FONT;
    self.textField.backgroundColor = [UIColor clearColor];
    self.textField.delegate = self;

    [self addSubview:self.textField];
}

- (void)configureLabel
{
    CGFloat labelX = self.separatorInset.left;
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
   



}

+ (BZGTextViewCell *)parentCellForTextField:(UITextView *)textField
{
    UIView *view = textField;
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGFormCell class]]) break;
    }
    return (BZGTextViewCell *)view;
}

- (void)setShowsCheckmarkWhenValid:(BOOL)showsCheckmarkWhenValid
{
    _showsCheckmarkWhenValid = showsCheckmarkWhenValid;
    // Force RACObserve to trigger
    self.validationState = self.validationState;
}

-(void)setFloatingLabelYPadding:(CGFloat)floatingLabelYPadding
{
    if ([self.textField isKindOfClass:[JVFloatLabeledTextView class]]) {
        ((JVFloatLabeledTextView*)self.textField).floatingLabelYPadding = floatingLabelYPadding;
    }
}

- (void)setAccessoryViewImage:(UIImage *)image {
    self.accessoryView = [[UIImageView alloc] initWithImage:image];
    self.accessoryView.frame = CGRectMake(0, 0, 24, 24);
}

#pragma mark - UITextField notification selectors
// I'm using these notifications to flush the validation state signal.
// It works, but seems hacky. Is there a better way?

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([textField isEqual:self.textField]) {
        self.validationState = self.validationState;
    }
}

-(void)setText:(NSString *)text
{
    self.textField.text = text;

    if ([self.textField.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.textField.delegate textViewDidChange:self.textField];
    }
    
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

- (CGFloat)cellHeight
{
//    CGRect contentViewFrame = self.contentView.frame;
//    contentViewFrame.size.height = self.textField.frame.origin.y + self.textField.frame.size.height + 15;
//    self.contentView.frame = contentViewFrame;
    
    CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
    CGFloat height = ceilf(textViewSize.height) + self.textField.frame.origin.y + 15; /*FXFormFieldPaddingTop + FXFormFieldPaddingBottom*/;
    return height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
}

- (void)validate
{
    // Validation will be triggered when the text is set to the current textField text
    [self setText:self.textField.text];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
