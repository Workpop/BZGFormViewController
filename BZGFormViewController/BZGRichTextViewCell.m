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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(textFieldTextDidEndEditing:)
//                                                 name:UITextFieldTextDidEndEditingNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(textFieldTextDidChange:)
//                                                 name:UITextFieldTextDidChangeNotification
//                                               object:nil];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect textViewFrame = self.holder.frame;
    textViewFrame.size.width = self.contentView.bounds.size.width;
    textViewFrame.size.height = self.contentView.frame.size.height;
    self.holder.frame = textViewFrame;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.height = self.holder.frame.origin.y + self.holder.frame.size.height;
    self.contentView.frame = contentViewFrame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureLabel
{
    self.holder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BZG_TEXTVIEW_MIN_HEIGHT)];
    self.holder.backgroundColor = [UIColor blueColor];
    [self.contentView addSubview:self.holder];
    
    self.richText = [[ZSSRichTextEditor alloc] initWithView:self.holder];
    self.richText.enabledToolbarItems = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarItalic, ZSSRichTextEditorToolbarUnorderedList, ZSSRichTextEditorToolbarOrderedList];
    [self.richText setPlaceholder:@"This is a test"];
    
    self.contentView.backgroundColor = [UIColor clearColor];
}

- (void)configureTap {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)];
    [self.contentView addGestureRecognizer:tap];
}

+ (BZGRichTextViewCell *)parentCellForRichTextView:(UIView *)view
{
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGFormCell class]]) break;
    }
    return (BZGRichTextViewCell *)view;
}

#pragma mark - UITextField notification selectors

//- (void)textFieldTextDidChange:(NSNotification *)notification
//{
//    if ([self.richText.delegate respondsToSelector:@selector(richTextViewDidChange::)]) {
//        [self.richText.delegate richTextEditorViewDidChange:self.richText];
//    }
//}

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
