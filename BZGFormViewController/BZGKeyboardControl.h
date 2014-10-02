//
//  BZGKeyboardControl.h
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <UIKit/UIKit.h>
#import <TOMSMorphingLabel/TOMSMorphingLabel.h>

@class BZGFormCell;

@interface BZGKeyboardControl : UIView

@property (nonatomic, strong) UIBarButtonItem *previousButton;
@property (nonatomic, strong) UIBarButtonItem *nextButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) BZGFormCell *previousCell;
@property (nonatomic, strong) BZGFormCell *currentCell;
@property (nonatomic, strong) BZGFormCell *nextCell;
@property (nonatomic, strong) TOMSMorphingLabel *textLabel;

@end
