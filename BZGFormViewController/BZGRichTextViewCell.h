//
//  BZGTextFieldCell.h
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <UIKit/UIKit.h>
#import <JVFloatLabeledTextField/JVFloatLabeledTextView.h>
#import "BZGFormCell.h"
#import "ZSSRichTextEditor.h"

@interface BZGRichTextViewCell : BZGFormCell

- (instancetype)initWithContentInsets:(UIEdgeInsets)contentInsets;

@property (strong, nonatomic) ZSSRichTextEditor *richText;
@property (strong, nonatomic) UILabel *label;

/// The block called when the text field's text begins editing.
@property (copy, nonatomic) void (^didBeginEditingBlock)(BZGRichTextViewCell *cell, NSString *text);

/**
 * The block called before the text field's text changes.
 * The block's newText parameter will be the text field's text after changing. Return NO if the text shouldn't change.
 */
@property (copy, nonatomic) BOOL (^shouldChangeTextBlock)(BZGRichTextViewCell *cell, NSString *newText);

/// The block called when the text field's text ends editing.
@property (copy, nonatomic) void (^didEndEditingBlock)(BZGRichTextViewCell *cell, NSString *text);

/// The block called before the text field returns. Return NO if the text field shouldn't return.
@property (copy, nonatomic) BOOL (^shouldReturnBlock)(BZGRichTextViewCell *cell, NSString *text);

/// Set the textField text
-(void)setText:(NSString *)text;

- (CGFloat)cellHeight;

/**
 * Returns the parent BZGTextFieldCell for the given text field. If no cell is found, returns nil.
 *
 * @param textField A UITextField instance that may or may not belong to this BZGTextFieldCell instance.
 */
//+ (BZGRichTextViewCell *)parentCellForTextField:(UITextView *)textField;

+ (BZGRichTextViewCell *)parentCellForRichTextView:(UIView *)view;

@end
