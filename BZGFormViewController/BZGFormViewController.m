//
//  BZGFormViewController.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import "BZGFormViewController.h"

#import "BZGFormCell.h"
#import "BZGInfoCell.h"
#import "BZGPhoneTextFieldCell.h"
#import "BZGTextFieldCell.h"
#import "BZGTextViewCell.h"

#import "BZGDateTextFieldCell.h"
#import "BZGStateTextFieldCell.h"
#import "BZGMonthYearTextFieldCell.h"

#import "BZGKeyboardControl.h"
#import "Constants.h"

@interface BZGFormViewController ()

@property (nonatomic, assign) UITableViewStyle style;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong) BZGKeyboardControl *keyboardControl;
@property (nonatomic, copy) void (^didEndScrollingBlock)();
@property (nonatomic, strong) NSMutableArray *formCellsBySection;
@property (nonatomic, strong) NSArray *allFormCellsFlattened;
@property (nonatomic, weak) BZGFormCell *currentlyEditingCell;

@end

@implementation BZGFormViewController

- (id)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if (self) {
        _formCellsBySection = [NSMutableArray array];
        _style = style;
        _showsValidationCell = YES;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:self.style];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizesSubviews = YES;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = BZG_TABLEVIEW_BACKGROUND_COLOR;

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.autoresizesSubviews = YES;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [contentView addSubview:self.tableView];

    self.view = contentView;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

#pragma mark - Showing/hiding info cells

- (BZGInfoCell *)infoCellBelowFormCell:(BZGTextFieldCell *)cell
{
    NSIndexPath *cellIndexPath = [self indexPathOfCell:cell];
    NSArray *formCellsInSection = [self formCellsInSection:cellIndexPath.section];
    
    if (cellIndexPath == nil || cellIndexPath.row + 1 >= [formCellsInSection count]) { return nil; }

    UITableViewCell *cellBelow = formCellsInSection[cellIndexPath.row + 1];
    if ([cellBelow isKindOfClass:[BZGInfoCell class]]) {
        [self styleInfoCell:cell];
        return (BZGInfoCell *)cellBelow;
    }

    return nil;
}

- (void)showInfoCellBelowFormCell:(BZGTextFieldCell *)cell
{
    NSIndexPath *cellIndexPath = [self indexPathOfCell:cell];
    if (cellIndexPath == nil) { return; }

    // if an info cell is already showing, do nothing
    BZGInfoCell *infoCell = [self infoCellBelowFormCell:cell];
    if (infoCell) { return; }

    // otherwise, add the cell's info cell to the table view
    NSIndexPath *infoCellIndexPath = [NSIndexPath indexPathForRow:cellIndexPath.row + 1
                                                        inSection:cellIndexPath.section];
    [self styleInfoCell:cell];
    [self insertFormCells:[@[cell.infoCell] mutableCopy] atIndexPath:infoCellIndexPath];
    [self.tableView insertRowsAtIndexPaths:@[infoCellIndexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)styleInfoCell:(BZGTextFieldCell*)cell
{
    cell.infoCell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(self.tableView.bounds)/2.0, 0, CGRectGetWidth(self.tableView.bounds)/2.0);
    cell.infoCell.backgroundColor = cell.infoCell.contentView.backgroundColor = [UIColor whiteColor];
    if (cell.validationState == BZGValidationStateInvalid) {
        cell.infoCell.infoLabel.textColor = BZG_RED_COLOR;
    }
}

- (void)removeInfoCellBelowFormCell:(BZGTextFieldCell *)cell
{
    NSIndexPath *cellIndexPath = [self indexPathOfCell:cell];
    if (cellIndexPath == nil) { return; }

    // if no info cell is showing, do nothing
    BZGInfoCell *infoCell = [self infoCellBelowFormCell:cell];
    if (!infoCell) return;

    // otherwise, remove it
    NSIndexPath *infoCellIndexPath = [NSIndexPath indexPathForRow:cellIndexPath.row + 1
                                                        inSection:cellIndexPath.section];
    [self removeFormCellAtIndexPath:infoCellIndexPath];
    [self.tableView deleteRowsAtIndexPaths:@[infoCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self styleInfoCell:cell];
}

- (void)updateInfoCellBelowFormCell:(BZGTextFieldCell *)cell
{
    if (self.showsValidationCell &&
        !cell.textField.editing &&
        [cell.infoCell.infoLabel.text length] &&
        (cell.validationState == BZGValidationStateInvalid ||
         cell.validationState == BZGValidationStateWarning)) {
            [self showInfoCellBelowFormCell:cell];
        } else {
            [self removeInfoCellBelowFormCell:cell];
        }
    
    [self fixSeparator];
}

- (void)setShowsValidationCell:(BOOL)showsValidationCell
{
    _showsValidationCell = showsValidationCell;
    for (BZGTextFieldCell *cell in [self allFormCellsFlattened]) {
        if ([cell isKindOfClass:[BZGTextFieldCell class]]) {
            [self updateInfoCellBelowFormCell:cell];
        }
    }
}

#pragma mark - Finding cells

- (BZGTextFieldCell *)firstFormCellWithValidationState:(BZGValidationState)validationState
{
    for (UITableViewCell *cell in [self allFormCellsFlattened]) {
        if ([cell isKindOfClass:[BZGTextFieldCell class]]) {
            if (((BZGTextFieldCell *)cell).validationState == validationState) {
                return (BZGTextFieldCell *)cell;
            }
        }
    }
    return nil;
}

- (BZGTextFieldCell *)firstInvalidFormCell
{
    return [self firstFormCellWithValidationState:BZGValidationStateInvalid];
}

- (BZGTextFieldCell *)firstWarningFormCell
{
    return [self firstFormCellWithValidationState:BZGValidationStateWarning];
}

- (BZGFormCell *)nextFormCell:(BZGFormCell *)cell
{
    NSIndexPath *cellIndexPath = [self indexPathOfCell:cell];
    if (cellIndexPath == nil) { return nil; }

    for (NSInteger s = cellIndexPath.section; s < [self.formCellsBySection count]; s++) {
        NSArray* formCellsInSection = [self formCellsInSection:s];
        
        NSInteger startRow = (s == cellIndexPath.section) ? cellIndexPath.row + 1 : 0;
        for (NSInteger r = startRow; r < [formCellsInSection count]; ++r) {
            UITableViewCell *cell = formCellsInSection[r];
            if ([cell isKindOfClass:[BZGFormCell class]]) {
                return (BZGFormCell *)cell;
            }
        }
    }
    return nil;
}

- (BZGFormCell *)previousFormCell:(BZGFormCell *)cell
{
    NSIndexPath *cellIndexPath = [self indexPathOfCell:cell];
    if (cellIndexPath == nil) { return nil; }
    
    for (NSInteger s = cellIndexPath.section; s >= 0; s--) {
        NSArray* formCellsInSection = [self formCellsInSection:s];
        
        NSInteger startRow = (s == cellIndexPath.section) ? cellIndexPath.row - 1 : [formCellsInSection count] - 1;
        for (NSInteger r = startRow; r >= 0; r--) {
            UITableViewCell *cell = formCellsInSection[r];
            if ([cell isKindOfClass:[BZGFormCell class]]) {
                return (BZGFormCell *)cell;
            }
        }
    }
    return nil;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *formCells = [self formCellsInSection:section];
    return formCells ? [formCells count] : 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.formCellsBySection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *formCells = [self formCellsInSection:indexPath.section];
    
    if (formCells) {
        return [formCells objectAtIndex:indexPath.row];
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *formCells = [self formCellsInSection:indexPath.section];
    
    if (formCells) {
        UITableViewCell *cell = [formCells objectAtIndex:indexPath.row];
        if ([cell isKindOfClass:[BZGInfoCell class]]) {
            return 20;
        }
        return cell.frame.size.height;
    }
    return 0;
}

#pragma mark - UITextViewDelegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    BZGTextViewCell *cell = (BZGTextViewCell*)[BZGTextViewCell parentCellForTextField:textView];
    if (!cell) {
        return NO;
    }
    
    if (self.showsKeyboardControl) {
        [self accesorizeTextView:textView];
    }
    
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    BZGTextViewCell *cell = (BZGTextViewCell*)[BZGTextViewCell parentCellForTextField:textView];
    if (!cell) {
        return;
    }
    
    // store the cell we are currently editing
    self.currentlyEditingCell = cell;
    
    if (cell.didBeginEditingBlock) {
        cell.didBeginEditingBlock(cell, textView.text);
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

-(void)textViewDidChange:(UITextView *)textView
{
    //resize the tableview if required
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [self fixSeparator];
    
    //scroll to show cursor
    CGRect cursorRect = [textView caretRectForPosition:textView.selectedTextRange.end];
    CGRect tableViewrect = [self.tableView convertRect:cursorRect fromView:textView];
    
    [self.tableView scrollRectToVisible:tableViewrect animated:YES];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    BZGTextViewCell *cell = (BZGTextViewCell*)[BZGTextViewCell parentCellForTextField:textView];
    if (!cell) {
        return YES;
    }
    
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (cell.shouldChangeTextBlock) {
        shouldChange = cell.shouldChangeTextBlock(cell, newText);
    }

    return shouldChange;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    BZGTextViewCell *cell = [BZGTextViewCell parentCellForTextField:textView];
    if (!cell) {
        return;
    }
    
    self.currentlyEditingCell = nil;
    
    if (cell.didEndEditingBlock) {
        cell.didEndEditingBlock(cell, textView.text);
    }
}


#pragma mark - UITextFieldDelegate


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    BZGTextFieldCell *cell = [BZGTextFieldCell parentCellForTextField:textField];
    if (!cell) {
        return;
    }
    
    // store currently editing cell
    self.currentlyEditingCell = cell;
    
    if (cell.didBeginEditingBlock) {
        cell.didBeginEditingBlock(cell, textField.text);
    }

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    if (self.showsKeyboardControl) {
        [self accesorizeTextField:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChange = YES;
    BZGTextFieldCell *cell = [BZGTextFieldCell parentCellForTextField:textField];
    if (!cell) {
        return YES;
    }

    if ([cell isMemberOfClass:[BZGPhoneTextFieldCell class]]) {
        BZGPhoneTextFieldCell *phoneCell = (BZGPhoneTextFieldCell *)cell;
        BOOL shouldChange = [phoneCell shouldChangeCharactersInRange:range replacementString:string];
        [self updateInfoCellBelowFormCell:phoneCell];
        return shouldChange;
    }

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (cell.shouldChangeTextBlock) {
        shouldChange = cell.shouldChangeTextBlock(cell, newText);
    }

    [self updateInfoCellBelowFormCell:cell];
    return shouldChange;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{    
    BZGTextFieldCell *cell = [BZGTextFieldCell parentCellForTextField:textField];
    if (!cell) {
        return;
    }
    
    self.currentlyEditingCell = nil;
    
    if (cell.didEndEditingBlock) {
        cell.didEndEditingBlock(cell, textField.text);
    }

    [self updateInfoCellBelowFormCell:cell];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    BZGTextFieldCell *cell = [BZGTextFieldCell parentCellForTextField:textField];
    if (!cell) {
        return YES;
    }

    if (cell.shouldReturnBlock) {
        shouldReturn = cell.shouldReturnBlock(cell, textField.text);
    }

    BZGFormCell *nextCell = [self nextFormCell:cell];
    if (!nextCell) {
        [cell resignFirstResponder];
    }
    else {
        [nextCell becomeFirstResponder];
    }

    [self updateInfoCellBelowFormCell:cell];
    return shouldReturn;
}

#pragma mark - Updating Cells

- (void)beginUpdates
{
    [self.tableView beginUpdates];
}

- (void)endUpdates
{
    [self.tableView endUpdates];
    
    if ([self.currentlyEditingCell isKindOfClass:BZGTextViewCell.class]) {
        BZGTextViewCell *textViewCell = (BZGTextViewCell *)self.currentlyEditingCell;
        [self accesorizeTextView:textViewCell.textField];
    }
    
    if ([self.currentlyEditingCell isKindOfClass:BZGTextFieldCell.class]) {
        BZGTextFieldCell *textFieldCell = (BZGTextFieldCell *)self.currentlyEditingCell;
        [self accesorizeTextField:textFieldCell.textField];
    }
    
    [self fixSeparator];
}

- (void)fixSeparator
{
    UITableViewCellSeparatorStyle style = self.tableView.separatorStyle;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorStyle = style;
}

#pragma mark - BZGFormCellDelegate

- (void)formCell:(BZGFormCell *)formCell didChangeValidationState:(BZGValidationState)validationState
{
    BOOL isValid = YES;
    for (BZGFormCell *cell in [self allFormCellsFlattened]) {
        if ([cell isKindOfClass:[BZGFormCell class]]) {
            isValid = isValid &&
            (cell.validationState == BZGValidationStateValid ||
             cell.validationState == BZGValidationStateWarning);
        }
    }
    self.isValid = isValid;
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }

    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}


- (void)keyboardWillHide:(NSNotification *)notification
{
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}



#pragma mark - BZGKeyboardControl Methods

- (void)accesorizeTextField:(UITextField *)textField
{
    BZGTextFieldCell *cell = [BZGTextFieldCell parentCellForTextField:textField];
    self.keyboardControl.previousCell = [self previousFormCell:cell];
    self.keyboardControl.currentCell = cell;
    self.keyboardControl.nextCell = [self nextFormCell:cell];
    textField.inputAccessoryView = self.keyboardControl;
}

- (void)accesorizeTextView:(UITextView *)textField
{
    BZGTextViewCell *cell = [BZGTextViewCell parentCellForTextField:textField];
    self.keyboardControl.previousCell = [self previousFormCell:cell];
    self.keyboardControl.currentCell = cell;
    self.keyboardControl.nextCell = [self nextFormCell:cell];
    textField.inputAccessoryView = self.keyboardControl;
}

- (BZGKeyboardControl *)keyboardControl
{
    if (!_keyboardControl) {
        _keyboardControl = [[BZGKeyboardControl alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), BZG_KEYBOARD_CONTROL_HEIGHT)];
        _keyboardControl.previousButton.target = self;
        _keyboardControl.previousButton.action = @selector(navigateToPreviousCell:);
        _keyboardControl.nextButton.target = self;
        _keyboardControl.nextButton.action = @selector(navigateToNextCell);
        _keyboardControl.doneButton.target = self;
        _keyboardControl.doneButton.action = @selector(doneButtonPressed);
    }
    return _keyboardControl;
}

- (void)navigateToPreviousCell: (id)sender
{
    BZGFormCell *previousCell = self.keyboardControl.previousCell;
    
    //if next cell can become first responder
    if ([previousCell canBecomeFirstResponder]) {
        [self navigateToDestinationCell:previousCell];
    }
    //else find the next cell that can become first responder
    else{
        //get row for previousCell cell
        NSIndexPath * indexPath = [self indexPathOfCell:previousCell];
        NSInteger rowNumber = 0;
        for (NSInteger i = 0; i < indexPath.section; i++) {
            rowNumber += [self tableView:self.tableView numberOfRowsInSection:i];
        }
        rowNumber += indexPath.row;
        
        //find the cell that can become first responder and go to that
        for (NSInteger i = rowNumber; i < self.allFormCellsFlattened.count; i--) {
            BZGFormCell * cell = [self.allFormCellsFlattened objectAtIndex:i];
            if ([cell canBecomeFirstResponder]) {
                [self navigateToDestinationCell:cell];
                break;
            }
        }
    }
}

- (void)navigateToNextCell
{
    BZGFormCell *nextCell = self.keyboardControl.nextCell;
    
    //if next cell can become first responder
    if ([nextCell canBecomeFirstResponder]) {
        [self navigateToDestinationCell:nextCell];
    }
    //else find the next cell that can become first responder
    else{
        //get row for next cell
        NSIndexPath * indexPath = [self indexPathOfCell:nextCell];
        NSInteger rowNumber = 0;
        for (NSInteger i = 0; i < indexPath.section; i++) {
            rowNumber += [self tableView:self.tableView numberOfRowsInSection:i];
        }
        rowNumber += indexPath.row;
        
        //find the cell that can become first responder and go to that
        for (NSInteger i = rowNumber; i < self.allFormCellsFlattened.count; i++) {
            BZGFormCell * cell = [self.allFormCellsFlattened objectAtIndex:i];
            if ([cell canBecomeFirstResponder]) {
                [self navigateToDestinationCell:cell];
                break;
            }
        }
    }
}

- (void)navigateToDestinationCell:(BZGFormCell *)destinationCell
{
    if ([[self.tableView visibleCells] containsObject:destinationCell]) {
        [destinationCell becomeFirstResponder];
    }
    else {
        NSIndexPath *cellIndexPath = [self indexPathOfCell:destinationCell];
        self.didEndScrollingBlock = ^{
            [destinationCell becomeFirstResponder];
        };
        [self.tableView scrollToRowAtIndexPath:cellIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)doneButtonPressed
{
    [self.keyboardControl.currentCell resignFirstResponder];
}

#pragma mark - UIScrollView Methods

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        if (self.didEndScrollingBlock) {
            self.didEndScrollingBlock();
            self.didEndScrollingBlock = nil;
        }
    }
}

#pragma mark - formCells Methods

- (void)setFormCells:(NSMutableArray *)formCells
{
    [self removeAllFormCells];
    [self addFormCells:formCells atSection:self.formSection];
}

- (NSArray *)formCells
{
    return [self formCellsInSection:self.formSection];
}

- (NSArray *)allFormCells
{
    return [self.formCellsBySection copy];
}

- (NSArray *)allFormCellsFlattened
{
    NSMutableArray *flattenedCellArray = [[NSMutableArray alloc] init];
    for (NSArray *cellArray in self.allFormCells) {
        [flattenedCellArray addObjectsFromArray:cellArray];
    }
    return flattenedCellArray;
}

- (void)prepareCell:(BZGFormCell *)cell
{
    if ([cell isKindOfClass:[BZGFormCell class]]) {
        cell.delegate = self;
        
        if ([cell isKindOfClass:[BZGTextFieldCell class]]) {
            ((BZGTextFieldCell *)cell).textField.delegate = self;
        }
        else if ([cell isKindOfClass:[BZGTextViewCell class]]) {
            ((BZGTextViewCell *)cell).textField.delegate = self;
        }
        
    } else if (![cell isKindOfClass:[BZGInfoCell class]]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"BZGFormViewController only accepts cells that subclass BZGFormCell or BZGInfoCell"];
    }
}

- (NSArray *)formCellsInSection:(NSInteger)section
{
    return [[self mutableFormCellsInSection:section] copy];
}

- (NSMutableArray *)mutableFormCellsInSection:(NSInteger)section
{
    if ([self.formCellsBySection count] > section) {
        return [self.formCellsBySection objectAtIndex:section];
    } else {
        return [NSMutableArray array];
    }
}

- (void)addFormCell:(BZGFormCell *)formCell atSection:(NSInteger)section
{
    [self addFormCells:@[formCell] atSection:section];
}

- (void)addFormCells:(NSArray *)formCells atSection:(NSInteger)section
{
    NSInteger formCellCount = [[self formCellsInSection:section] count];
    [self insertFormCells:formCells atIndexPath:[NSIndexPath indexPathForRow:formCellCount inSection:section]];
}

- (void)insertFormCells:(NSArray *)formCells atIndexPath:(NSIndexPath *)indexPath
{
    self.allFormCellsFlattened = nil;
    for (BZGFormCell *cell in formCells) {
        [self prepareCell:cell];
    }
    
    while (indexPath.section + 1 > [self.formCellsBySection count]) {
        [self.formCellsBySection addObject:[NSMutableArray array]];
    }
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row, [formCells count])];
    [[self.formCellsBySection objectAtIndex:indexPath.section] insertObjects:formCells atIndexes:indexSet];
}

- (void)removeFormCellAtIndexPath:(NSIndexPath *)indexPath
{
    self.allFormCellsFlattened = nil;
    NSMutableArray *formCells = [self mutableFormCellsInSection:indexPath.section];
    if (formCells) {
        [formCells removeObjectAtIndex:indexPath.row];
    }
}

- (void)removeFormCellsInSection:(NSInteger)section
{
    self.allFormCellsFlattened = nil;
    if ([self.formCellsBySection count] > section) {
        self.formCellsBySection[section] = [NSMutableArray array];
    }
}

- (void)removeAllFormCells
{
    self.allFormCellsFlattened = nil;
    self.formCellsBySection = [NSMutableArray array];
}

- (NSIndexPath *)indexPathOfCell:(BZGFormCell *)cell
{
    for (NSArray *section in self.formCellsBySection) {
        for (BZGFormCell *sectionCell in section) {
            if (cell == sectionCell) {
                return [NSIndexPath indexPathForRow:[section indexOfObject:cell]
                                          inSection:[self.formCellsBySection indexOfObject:section]];
            }
        }
    }
    return nil;
}

@end
