//
//  BZGSwitchCell.m
//  Pods
//
//  Created by Seth Sandler on 10/1/14.
//
//

#import "BZGSwitchCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@implementation BZGSwitchCell

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
    self.infoCell = [[BZGInfoCell alloc] init];
    
    [self configureSwitchField];
    [self configureLabel];
    [self configureTap];
}

-(void)layoutSubviews
{
    
    [super layoutSubviews];
    
    if (self.switchField) {
        
        CGFloat textFieldX = self.frame.size.width - self.switchField.frame.size.width - 15;
        CGFloat textFieldY = self.frame.size.height/2  - self.switchField.frame.size.height/2;
        CGRect textFieldFrame = CGRectMake(textFieldX,
                                           textFieldY,
                                           self.bounds.size.width - textFieldX,
                                           self.bounds.size.height);
        self.switchField.frame = textFieldFrame;
    }
}

- (void)configureSwitchField
{
    self.switchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.switchField = [[UISwitch alloc] initWithFrame:CGRectZero];
    
    CGFloat textFieldX = self.frame.size.width - self.switchField.frame.size.width - 15;
    CGFloat textFieldY = self.frame.size.height/2  - self.switchField.frame.size.height/2;
    CGRect textFieldFrame = CGRectMake(textFieldX,
                                       textFieldY,
                                       self.bounds.size.width - textFieldX,
                                       self.bounds.size.height);
    self.switchField.frame = textFieldFrame;
    [self addSubview:self.switchField];
}

- (void)configureLabel
{
    CGFloat labelX = 15;
    CGRect labelFrame = CGRectMake(labelX,
                                   0,
                                   self.switchField.frame.origin.x - labelX,
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

@end