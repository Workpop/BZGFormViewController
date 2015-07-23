//
//  BZGTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>

#import "BZGRichTextViewCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@interface BZGRichTextViewCell () <UITextViewDelegate>

@property (nonatomic, strong) UIView *holder;

@end

@implementation BZGRichTextViewCell

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.holder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BZG_TEXTVIEW_MIN_HEIGHT)];
    
    self.richText = [[ZSSRichTextEditor alloc] initWithView:self.holder];
    self.richText.shouldShowKeyboard = NO;
   
    [self configureLabel];
    [self configureTap];
    
    
    [self.contentView addSubview:self.holder];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldTextDidEndEditing:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldTextDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    
        CGRect textViewFrame = self.holder.frame;
        textViewFrame.origin.x = self.separatorInset.left;
        textViewFrame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
        textViewFrame.size.width = self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
    
    //CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
    
    //    CGFloat height = ceilf(textViewSize.height);
    //    height =  height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
   //     textViewFrame.size.height =  height;
   /*     if (![self.textLabel.text length])
        {
            textViewFrame.origin.y = self.textLabel.frame.origin.y;
        }
  */
        self.holder.frame = textViewFrame;
    
        textViewFrame.origin.x += 5;
        textViewFrame.size.width -= 5;
        self.detailTextLabel.frame = textViewFrame;
    
        CGRect contentViewFrame = self.contentView.frame;
        contentViewFrame.size.height = self.holder.frame.origin.y + self.holder.frame.size.height + 15;
        self.contentView.frame = contentViewFrame;
    
    
    
    
//    CGRect textViewFrame = self.textField.frame;
//    textViewFrame.origin.x = self.separatorInset.left;
//    textViewFrame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
//    textViewFrame.size.width = self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
//    CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
//    CGFloat height = ceilf(textViewSize.height);
//    height =  height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
//    textViewFrame.size.height =  height;
//    if (![self.textLabel.text length])
//    {
//        textViewFrame.origin.y = self.textLabel.frame.origin.y;
//    }
//    self.textField.frame = textViewFrame;
//    
//    textViewFrame.origin.x += 5;
//    textViewFrame.size.width -= 5;
//    self.detailTextLabel.frame = textViewFrame;
//    
//    CGRect contentViewFrame = self.contentView.frame;
//    contentViewFrame.size.height = self.textField.frame.origin.y + self.textField.frame.size.height + 15;
//    self.contentView.frame = contentViewFrame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureTextField
{
    /*
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
     */
}

- (void)configureLabel
{
    CGFloat labelX = self.separatorInset.left;
    CGRect labelFrame = CGRectMake(labelX,
                                   0,
                                   self.bounds.size.width - labelX,
                                   self.bounds.size.height);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    self.label.font = BZG_TEXTFIELD_LABEL_FONT;
    self.label.textColor = BZG_TEXTFIELD_LABEL_COLOR;
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
}

- (void)configureTap {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)];
    [self.contentView addGestureRecognizer:tap];
}

+ (BZGRichTextViewCell *)parentCellForTextField:(UITextView *)textField
{
    UIView *view = textField;
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGFormCell class]]) break;
    }
    return (BZGRichTextViewCell *)view;
}

#pragma mark - UITextField notification selectors

-(void)setText:(NSString *)text
{
    /*
    self.textField.text = text;

    if ([self.textField.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.textField.delegate textViewDidChange:self.textField];
    }
     */
    
    [self.richText setHTML:text];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textField];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.richText];
}

- (void)textFieldTextDidEndEditing:(NSNotification *)notification
{
//    UITextField *textField = (UITextField *)notification.object;
//    if ([textField isEqual:self.textField]) {
//        self.validationState = self.validationState;
//    }
}

- (BOOL)becomeFirstResponder
{
    [self.richText focusTextEditor];
}

- (BOOL)resignFirstResponder
{
    [self.richText blurTextEditor];
}

- (CGFloat)cellHeight
{
//    CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
//    CGFloat height = ceilf(textViewSize.height);
//    return height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
    
    return BZG_TEXTVIEW_MIN_HEIGHT;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
