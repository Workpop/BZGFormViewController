//
//  BZGTextFieldCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "BZGRichTextViewCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@interface BZGRichTextViewCell () <UITextViewDelegate, ZSSRichTextEditorDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *richTextContainer;

@end

@implementation BZGRichTextViewCell

- (instancetype)initWithContentInsets:(UIEdgeInsets)contentInsets
{
    self = [super init];
    if (self) {
        self.separatorInset = contentInsets;
        [self setup];
    }
    return self;
}

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
    self.contentView.backgroundColor = [UIColor clearColor];

    [self configureLabel];
    [self configureRichText];
    [self configureTap];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.label.text.length) {
        // update rich text richTextContainer
        CGRect richTextContainerFrame = self.richTextContainer.frame;
        richTextContainerFrame.size.width = self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
        richTextContainerFrame.size.height = self.contentView.frame.size.height;
        richTextContainerFrame.origin.y = 16;
        self.richTextContainer.frame = richTextContainerFrame;
        
        // update contentViewFrame
        CGRect contentViewFrame = self.contentView.frame;
        contentViewFrame.size.height = self.richTextContainer.frame.origin.y + self.richTextContainer.frame.size.height;
        self.contentView.frame = contentViewFrame;
    } else {
        // update rich text richTextContainer
        CGRect richTextContainerFrame = self.richTextContainer.frame;
        richTextContainerFrame.size.width = self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
        richTextContainerFrame.size.height = self.contentView.frame.size.height - CGRectGetHeight(self.label.frame);
        self.richTextContainer.frame = richTextContainerFrame;
        
        // update contentViewFrame
        CGRect contentViewFrame = self.contentView.frame;
        contentViewFrame.size.height = self.richTextContainer.frame.origin.y + self.richTextContainer.frame.size.height;
        self.contentView.frame = contentViewFrame;
    }
    
    // update label frame
    CGRect labelFrame = self.label.frame;
    labelFrame.origin.x = self.separatorInset.left;
    labelFrame.size.width = self.bounds.size.width - self.separatorInset.left - self.separatorInset.right;
    self.label.frame = labelFrame;
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
                                   self.bounds.size.width - labelX - self.separatorInset.right,
                                   30);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    self.label.font = BZG_TEXTFIELD_LABEL_FONT;
    self.label.textColor = BZG_TEXTFIELD_LABEL_COLOR;
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
}

- (void)configureRichText
{
    self.richTextContainer = [[UIView alloc] initWithFrame:CGRectMake(self.separatorInset.left, CGRectGetHeight(self.label.frame), self.contentView.bounds.size.width - self.separatorInset.left - self.separatorInset.right, BZG_TEXTVIEW_MIN_HEIGHT)];
    self.richTextContainer.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.richTextContainer];
    
    self.richText = [[ZSSRichTextEditor alloc] initWithView:self.richTextContainer];
    self.richText.enabledToolbarItems = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarItalic, ZSSRichTextEditorToolbarUnorderedList, ZSSRichTextEditorToolbarOrderedList];
}

- (void)configureTap {
    
    self.contentView.userInteractionEnabled = YES;
    self.richTextContainer.userInteractionEnabled = YES;
    self.richText.editorView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)];
    [tap setNumberOfTapsRequired:1];
    [tap setNumberOfTouchesRequired:1];
    tap.delegate = self;
    [self.richText.editorView addGestureRecognizer:tap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // only listen to tap gesture when there's no text since the user wouldn't know where to tap
    // when there's text they'll see the text and tap in this area
    if (!self.richText.getText.length) {
        return YES;
    }
    
    return NO;
}

+ (BZGRichTextViewCell *)parentCellForRichTextView:(UIView *)view
{
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGFormCell class]]) break;
    }
    return (BZGRichTextViewCell *)view;
}


-(void)setText:(NSString *)text
{
    [self.richText setHTML:text];
}

- (void)handleTap
{
    [self.richText focusTextEditor];
}

- (BOOL)becomeFirstResponder
{
    [self.richText focusTextEditor];
    
    if ([self.richText.delegate respondsToSelector:@selector(richTextEditorViewShouldBeginEditing:)]) {
        [self.richText.delegate richTextEditorViewShouldBeginEditing:self.richText];
    }
    
    if([self.richText.delegate respondsToSelector:@selector(richTextEditorViewDidBeginEditing:)]) {
        [self.richText.delegate richTextEditorViewDidBeginEditing:self.richText];
    }
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self.richText blurTextEditor];
    
    return YES;
}

- (CGFloat)cellHeight
{
    CGFloat height = ceilf(self.richText.contentHeight) + CGRectGetHeight(self.label.frame) + 16;// 16 for padding;
    return height < BZG_TEXTVIEW_MIN_HEIGHT ? BZG_TEXTVIEW_MIN_HEIGHT: height;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
