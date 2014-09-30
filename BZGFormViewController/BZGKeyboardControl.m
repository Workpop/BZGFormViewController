//
//  BZGKeyboardControl.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "BZGKeyboardControl.h"
#import "BZGTextFieldCell.h"

const CGFloat BZGKeyboardControlButtonSpacing = 22;

@implementation BZGKeyboardControl

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        //add label in center for displaying hints/tips
        self.textLabel = [[TOMSMorphingLabel alloc] initWithFrame:CGRectMake(0 , 0, self.frame.size.width * .65, self.frame.size.height)];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor lightGrayColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        self.textLabel.numberOfLines = 0;
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.previousButton = [[UIBarButtonItem alloc] initWithTitle:@"Prev" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:nil action:nil];

        self.previousButton.enabled     = NO;
        self.nextButton.enabled         = NO;

        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.frame];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        //colors
        toolbar.barStyle = UIBarStyleBlackOpaque;
        toolbar.translucent = NO;
        
        //background color - match keyboard
        toolbar.barTintColor = [UIColor colorWithRed: 209/255.f green:213/255.f blue:219/255.f alpha:1];
        
        //button colors
        toolbar.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        
        [toolbar setItems:@[self.previousButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc] initWithCustomView:self.textLabel],
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            self.nextButton,
                            ]];
        [self addSubview:toolbar];
    }
    return self;
}


- (void)setPreviousCell:(BZGTextFieldCell *)previousCell {
    _previousCell = previousCell;
    self.previousButton.enabled = !!previousCell;
}


- (void)setNextCell:(BZGTextFieldCell *)nextCell {
    _nextCell = nextCell;
    self.nextButton.enabled = !!nextCell;
}

-(void)setCurrentCell:(BZGTextFieldCell *)currentCell
{
    _currentCell = currentCell;
    self.textLabel.text = currentCell.textField.accessibilityHint;
}

@end
