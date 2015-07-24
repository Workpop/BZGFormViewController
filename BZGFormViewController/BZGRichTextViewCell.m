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

@interface BZGRichTextViewCell () <UITextViewDelegate, ZSSRichTextEditorDelegate>

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
    [self configureLabel];
    [self configureTap];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect textViewFrame = self.holder.frame;
    textViewFrame.size.width = self.contentView.bounds.size.width;
    textViewFrame.size.height = self.contentView.frame.size.height;
    self.holder.frame = textViewFrame;
    
    //CGSize textViewSize = [self.textField sizeThatFits:CGSizeMake(self.textField.frame.size.width, FLT_MAX)];
    
    //    CGFloat height = ceilf(textViewSize.height);
    //    height =  height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
    //     textViewFrame.size.height =  height;
    /*     if (![self.textLabel.text length])
     {
     textViewFrame.origin.y = self.textLabel.frame.origin.y;
     }
     */

    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.height = self.holder.frame.origin.y + self.holder.frame.size.height + self.label.frame.size.height;
    self.contentView.frame = contentViewFrame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
//    [self addSubview:self.label];
    
    
    self.holder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BZG_TEXTVIEW_MIN_HEIGHT)];
    self.holder.backgroundColor = [UIColor blueColor];
    [self.contentView addSubview:self.holder];
    
    self.richText = [[ZSSRichTextEditor alloc] initWithView:self.holder];
    self.richText.enabledToolbarItems = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarItalic, ZSSRichTextEditorToolbarUnorderedList, ZSSRichTextEditorToolbarOrderedList, ZSSRichTextEditorToolbarQuickLink];
    self.richText.shouldShowKeyboard = NO;
//    self.richText.delegate = self;
    
    self.contentView.backgroundColor = [UIColor clearColor];
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
    [self.richText setHTML:text];
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
    CGFloat height = ceilf(self.richText.contentHeight);
    return self.richText.contentHeight < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: self.richText.contentHeight;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
