//
//  ZSSRichTextEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
#import "ZSSBarButtonItem.h"
#import "UIResponder+ZSSFirstResponder.h"

@interface UIWebView (HackishAccessoryHiding)
@property (nonatomic, assign) BOOL hidesInputAccessoryView;
@end

@implementation UIWebView (HackishAccessoryHiding)

static const char * const hackishFixClassName = "UIWebBrowserViewMinusAccessoryView";
static Class hackishFixClass = Nil;

- (UIView *)hackishlyFoundBrowserView {
    UIScrollView *scrollView = self.scrollView;
    
    UIView *browserView = nil;
    for (UIView *subview in scrollView.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"UIWebBrowserView"]) {
            browserView = subview;
            break;
        }
    }
    return browserView;
}

- (id)methodReturningNil {
    return nil;
}

- (void)ensureHackishSubclassExistsOfBrowserViewClass:(Class)browserViewClass {
    if (!hackishFixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        IMP nilImp = [self methodForSelector:@selector(methodReturningNil)];
        class_addMethod(newClass, @selector(inputAccessoryView), nilImp, "@@:");
        objc_registerClassPair(newClass);
        
        hackishFixClass = newClass;
    }
}

- (BOOL) hidesInputAccessoryView {
    UIView *browserView = [self hackishlyFoundBrowserView];
    return [browserView class] == hackishFixClass;
}

- (void) setHidesInputAccessoryView:(BOOL)value {
    UIView *browserView = [self hackishlyFoundBrowserView];
    if (browserView == nil) {
        return;
    }
    [self ensureHackishSubclassExistsOfBrowserViewClass:[browserView class]];
    
    if (value) {
        object_setClass(browserView, hackishFixClass);
    }
    else {
        Class normalClass = objc_getClass("UIWebBrowserView");
        object_setClass(browserView, normalClass);
    }
    [browserView reloadInputViews];
}

@end

@interface ZSSRichTextEditor ()
@property (nonatomic, strong) UIScrollView *toolBarScroll;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *toolbarHolder;
@property (nonatomic, strong) NSString *htmlString;
@property (nonatomic, strong) UITextView *sourceView;
@property (nonatomic) CGRect editorViewFrame;
@property (nonatomic) CGRect keyboardEnd;
@property (nonatomic) BOOL resourcesLoaded;
@property (nonatomic, strong) NSArray *editorItemsEnabled;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSString *selectedLinkURL;
@property (nonatomic, strong) NSString *selectedLinkTitle;
@property (nonatomic, strong) NSString *selectedImageURL;
@property (nonatomic, strong) NSString *selectedImageAlt;
@property (nonatomic, strong) UIBarButtonItem *keyboardItem;
@property (nonatomic, strong) NSMutableArray *customBarButtonItems;
@property (nonatomic, strong) NSMutableArray *customZSSBarButtonItems;
@property (nonatomic, strong) NSString *internalHTML;
@property (nonatomic) BOOL editorLoaded;

- (NSString *)removeQuotesFromHTML:(NSString *)html;
- (NSString *)tidyHTML:(NSString *)html;
- (void)enableToolbarItems:(BOOL)enable;
- (BOOL)isIpad;

@property (nonatomic, assign) UIView *view;

@end

@implementation ZSSRichTextEditor

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    
    if (self) {
        
        [self startMonitoring];
        
        self.view = view;
        
        // set initial height
        self.contentHeight = CGRectGetHeight(self.view.frame);
        
        self.editorLoaded = NO;
        self.shouldShowKeyboard = NO;
        self.formatHTML = NO;
        
        self.enabledToolbarItems = [[NSArray alloc] init];
        
        // Source View
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        self.sourceView = [[UITextView alloc] initWithFrame:frame];
        self.sourceView.hidden = YES;
        self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.sourceView.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        self.sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.sourceView.autoresizesSubviews = YES;
        [self.view addSubview:self.sourceView];
        
        // Editor View
        self.editorView = [[UIWebView alloc] initWithFrame:frame];
        self.editorView.delegate = self;
        //        self.editorView.hidesInputAccessoryView = YES;
        self.editorView.keyboardDisplayRequiresUserAction = NO;
        self.editorView.scalesPageToFit = YES;
        self.editorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleLeftMargin;
        self.editorView.dataDetectorTypes = UIDataDetectorTypeNone;
        self.editorView.scrollView.bounces = NO;
        self.editorView.scrollView.scrollEnabled = NO;
        self.editorView.backgroundColor = [UIColor clearColor];
        self.editorView.opaque = NO;
        
        self.editorView.scrollView.delegate = self;
        
        [self.view addSubview:self.editorView];
        
        // Scrolling View
        self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44)];
        self.toolBarScroll.backgroundColor = [UIColor clearColor];
        self.toolBarScroll.showsHorizontalScrollIndicator = NO;
        
        // Toolbar with icons
        self.toolbar = [[UIToolbar alloc] initWithFrame:self.toolBarScroll.frame];
        self.toolbar.backgroundColor = [UIColor clearColor];
        [self.toolBarScroll addSubview:self.toolbar];
        self.toolBarScroll.autoresizingMask = self.toolbar.autoresizingMask;
        
        // Background Toolbar
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.toolbar.frame), 44)];
        backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        backgroundToolbar.backgroundColor = [UIColor whiteColor];
        
        // Parent holding view
        self.toolbarHolder = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth(self.toolbar.frame), 44)];
        self.toolbarHolder.autoresizingMask = self.toolbar.autoresizingMask;
        [self.toolbarHolder addSubview:self.toolBarScroll];
        [self.toolbarHolder insertSubview:backgroundToolbar atIndex:0];
        
        // Hide Keyboard
        if (![self isIpad]) {
            
            // Toolbar holder used to crop and position toolbar
            UIView *toolbarCropper = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.toolbar.frame), 0, 44, 44)];
            toolbarCropper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            toolbarCropper.clipsToBounds = YES;
            
            // Use a toolbar so that we can tint
            UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(-7, -1, 44, 44)];
            [toolbarCropper addSubview:keyboardToolbar];
        }
        
        [[UIApplication sharedApplication].keyWindow addSubview:self.toolbarHolder];
        
        // Build the toolbar
        [self buildToolbar];
        
        if (!self.resourcesLoaded) {
            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"editor" ofType:@"html"];
            NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
            NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            NSString *source = [[NSBundle bundleForClass:[self class]] pathForResource:@"ZSSRichTextEditor" ofType:@"js"];
            NSString *jsString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:source] encoding:NSUTF8StringEncoding];
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--editor-->" withString:jsString];
            
            [self.editorView loadHTMLString:htmlString baseURL:self.baseURL];
            self.resourcesLoaded = YES;
        }
    }
    return self;
}

- (void)dealloc
{
    [self.toolbarHolder removeFromSuperview];
    [self stopMonitoring];
}

- (void)setEnabledToolbarItems:(NSArray *)enabledToolbarItems {
    
    _enabledToolbarItems = enabledToolbarItems;
    [self buildToolbar];
}


- (void)setToolbarItemTintColor:(UIColor *)toolbarItemTintColor {
    
    _toolbarItemTintColor = toolbarItemTintColor;
    
    // Update the color
    for (ZSSBarButtonItem *item in self.toolbar.items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    self.keyboardItem.tintColor = toolbarItemTintColor;
}


- (void)setToolbarItemSelectedTintColor:(UIColor *)toolbarItemSelectedTintColor {
    
    _toolbarItemSelectedTintColor = toolbarItemSelectedTintColor;
}


- (void)setPlaceholderText {
    
    if (!self.placeholder.length) {
        return;
    }
    
    NSString *js = [NSString stringWithFormat:@"zss_editor.setPlaceholder(\"%@\");", self.placeholder];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
}

- (NSArray *)itemsForToolbar {
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    // add a flexible space first
    ZSSBarButtonItem *flexibleBeginSpace = [[ZSSBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleBeginSpace];
    
    // None
    if(_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarNone])
    {
        return items;
    }
    
    // Bold
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarBold]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *bold = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSbold.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setBold)];
        bold.label = @"bold";
        [items addObject:bold];
    }
    
    // Italic
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarItalic]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *italic = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSitalic.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setItalic)];
        italic.label = @"italic";
        [items addObject:italic];
    }
    
    // Subscript
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarSubscript]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *subscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsubscript.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setSubscript)];
        subscript.label = @"subscript";
        [items addObject:subscript];
    }
    
    // Superscript
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarSuperscript]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *superscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsuperscript.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setSuperscript)];
        superscript.label = @"superscript";
        [items addObject:superscript];
    }
    
    // Strike Through
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarStrikeThrough]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *strikeThrough = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSstrikethrough.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setStrikethrough)];
        strikeThrough.label = @"strikeThrough";
        [items addObject:strikeThrough];
    }
    
    // Underline
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUnderline]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *underline = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunderline.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setUnderline)];
        underline.label = @"underline";
        [items addObject:underline];
    }
    
    // Remove Format
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRemoveFormat]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *removeFormat = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSclearstyle.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(removeFormat)];
        removeFormat.label = @"removeFormat";
        [items addObject:removeFormat];
    }
    
    // Undo
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUndo]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *undoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSundo.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(undo:)];
        undoButton.label = @"undo";
        [items addObject:undoButton];
    }
    
    // Redo
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRedo]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *redoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSredo.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(redo:)];
        redoButton.label = @"redo";
        [items addObject:redoButton];
    }
    
    // Align Left
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyLeft]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignLeft = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSleftjustify.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignLeft)];
        alignLeft.label = @"justifyLeft";
        [items addObject:alignLeft];
    }
    
    // Align Center
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyCenter]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignCenter = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSScenterjustify.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignCenter)];
        alignCenter.label = @"justifyCenter";
        [items addObject:alignCenter];
    }
    
    // Align Right
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyRight]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignRight = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSrightjustify.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignRight)];
        alignRight.label = @"justifyRight";
        [items addObject:alignRight];
    }
    
    // Align Justify
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyFull]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignFull = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSforcejustify.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignFull)];
        alignFull.label = @"justifyFull";
        [items addObject:alignFull];
    }
    
    // Paragraph
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarParagraph]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *paragraph = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSparagraph.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(paragraph)];
        paragraph.label = @"p";
        [items addObject:paragraph];
    }
    
    // Header 1
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH1]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h1 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh1.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading1)];
        h1.label = @"h1";
        [items addObject:h1];
    }
    
    // Header 2
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH2]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h2 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh2.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading2)];
        h2.label = @"h2";
        [items addObject:h2];
    }
    
    // Header 3
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH3]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h3 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh3.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading3)];
        h3.label = @"h3";
        [items addObject:h3];
    }
    
    // Heading 4
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH4]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h4 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh4.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading4)];
        h4.label = @"h4";
        [items addObject:h4];
    }
    
    // Header 5
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH5]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h5 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh5.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading5)];
        h5.label = @"h5";
        [items addObject:h5];
    }
    
    // Heading 6
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH6]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h6 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh6.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading6)];
        h6.label = @"h6";
        [items addObject:h6];
    }
    
    // Text Color
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarTextColor]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *textColor = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSStextcolor.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(textColor)];
        textColor.label = @"textColor";
        [items addObject:textColor];
    }
    
    // Unordered List
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUnorderedList]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *ul = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunorderedlist.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setUnorderedList)];
        ul.label = @"unorderedList";
        [items addObject:ul];
    }
    
    // Ordered List
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarOrderedList]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *ol = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSorderedlist.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setOrderedList)];
        ol.label = @"orderedList";
        [items addObject:ol];
    }
    
    // Horizontal Rule
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarHorizontalRule]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *hr = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSShorizontalrule.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setHR)];
        hr.label = @"horizontalRule";
        [items addObject:hr];
    }
    
    // Indent
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarIndent]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *indent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSindent.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setIndent)];
        indent.label = @"indent";
        [items addObject:indent];
    }
    
    // Outdent
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarOutdent]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *outdent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSoutdent.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setOutdent)];
        outdent.label = @"outdent";
        [items addObject:outdent];
    }
    
    // Image
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarInsertImage]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *insertImage = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSimage.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(insertImage)];
        insertImage.label = @"image";
        [items addObject:insertImage];
    }
    
    // Insert Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarInsertLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *insertLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSlink.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(insertLink)];
        insertLink.label = @"link";
        [items addObject:insertLink];
    }
    
    // Remove Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRemoveLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *removeLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunlink.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(removeLink)];
        removeLink.label = @"removeLink";
        [items addObject:removeLink];
    }
    
    // Quick Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarQuickLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *quickLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSquicklink.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(quickLink)];
        quickLink.label = @"quickLink";
        [items addObject:quickLink];
    }
    
    // Show Source
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarViewSource]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *showSource = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSviewsource.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(showHTMLSource:)];
        showSource.label = @"source";
        [items addObject:showSource];
    }
    
    // add a flexible space first
    ZSSBarButtonItem *flexibleEndSpace = [[ZSSBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleEndSpace];
    
    return [NSArray arrayWithArray:items];
}


- (void)buildToolbar {
    
    // Check to see if we have any toolbar items, if not, add them all
    NSArray *items = [self itemsForToolbar];
    if (items.count == 0 && !(_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarNone])) {
        _enabledToolbarItems = @[ZSSRichTextEditorToolbarAll];
        items = [self itemsForToolbar];
    }
    
    if (self.customZSSBarButtonItems != nil) {
        items = [items arrayByAddingObjectsFromArray:self.customZSSBarButtonItems];
    }
    
    // get the width before we add custom buttons
    CGFloat toolbarWidth = items.count == 0 ? 0.0f : (CGFloat)(items.count * 39) - 10;
    
    if(self.customBarButtonItems != nil)
    {
        items = [items arrayByAddingObjectsFromArray:self.customBarButtonItems];
        for(ZSSBarButtonItem *buttonItem in self.customBarButtonItems)
        {
            toolbarWidth += buttonItem.customView.frame.size.width + 11.0f;
        }
    }
    
    self.toolbar.items = items;
    for (ZSSBarButtonItem *item in items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    
    self.toolbar.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44);
    self.toolBarScroll.contentSize = CGSizeMake(CGRectGetWidth(self.toolbar.frame), 44);
}

- (void)startMonitoring
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)stopMonitoring
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Editor Interaction

- (void)focusTextEditor {
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"zss_editor.focusWysiwyg();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)blurTextEditor {
    NSString *js = [NSString stringWithFormat:@"zss_editor.blurEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setHTML:(NSString *)html {
    
    // remove backslash that causes html not to render
    html = [html stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];

    self.internalHTML = html;
    
    if (self.editorLoaded) {
        [self updateHTML];
    }
    
}

- (void)updateHTML {
    NSString *html = self.internalHTML;
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:self.sourceView.text];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.setHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (NSString *)getHTML {
    NSString *html = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getHTML();"];
    html = [self removeQuotesFromHTML:html];
    html = [self tidyHTML:html];
    return html;
}


- (void)insertHTML:(NSString *)html {
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (NSString *)getText {
    return [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getText();"];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)showHTMLSource:(ZSSBarButtonItem *)barButtonItem {
    if (self.sourceView.hidden) {
        self.sourceView.text = [self getHTML];
        self.sourceView.hidden = NO;
        barButtonItem.tintColor = [UIColor blackColor];
        self.editorView.hidden = YES;
        [self enableToolbarItems:NO];
    } else {
        [self setHTML:self.sourceView.text];
        barButtonItem.tintColor = [self barButtonItemDefaultColor];
        self.sourceView.hidden = YES;
        self.editorView.hidden = NO;
        [self enableToolbarItems:YES];
    }
}

- (void)removeFormat {
    NSString *trigger = @"zss_editor.removeFormating();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignLeft {
    NSString *trigger = @"zss_editor.setJustifyLeft();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignCenter {
    NSString *trigger = @"zss_editor.setJustifyCenter();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignRight {
    NSString *trigger = @"zss_editor.setJustifyRight();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignFull {
    NSString *trigger = @"zss_editor.setJustifyFull();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setBold {
    NSString *trigger = @"zss_editor.setBold();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setItalic {
    NSString *trigger = @"zss_editor.setItalic();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSubscript {
    NSString *trigger = @"zss_editor.setSubscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnderline {
    NSString *trigger = @"zss_editor.setUnderline();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSuperscript {
    NSString *trigger = @"zss_editor.setSuperscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setStrikethrough {
    NSString *trigger = @"zss_editor.setStrikeThrough();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnorderedList {
    NSString *trigger = @"zss_editor.setUnorderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOrderedList {
    NSString *trigger = @"zss_editor.setOrderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setHR {
    NSString *trigger = @"zss_editor.setHorizontalRule();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setIndent {
    NSString *trigger = @"zss_editor.setIndent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOutdent {
    NSString *trigger = @"zss_editor.setOutdent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading1 {
    NSString *trigger = @"zss_editor.setHeading('h1');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading2 {
    NSString *trigger = @"zss_editor.setHeading('h2');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading3 {
    NSString *trigger = @"zss_editor.setHeading('h3');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading4 {
    NSString *trigger = @"zss_editor.setHeading('h4');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading5 {
    NSString *trigger = @"zss_editor.setHeading('h5');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading6 {
    NSString *trigger = @"zss_editor.setHeading('h6');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)paragraph {
    NSString *trigger = @"zss_editor.setParagraph();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)undo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.undo();"];
}

- (void)redo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.redo();"];
}

- (void)insertLink {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Show the dialog for inserting or editing a link
    [self showInsertLinkDialogWithLink:self.selectedLinkURL title:self.selectedLinkTitle];
}


- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedLinkURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertURLAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Title", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (title) {
                textField.text = title;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *linkURL = [alertController.textFields objectAtIndex:0];
            UITextField *title = [alertController.textFields objectAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
                NSLog(@"insert link");
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
            [self focusTextEditor];
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 2;
        UITextField *linkURL = [self.alertView textFieldAtIndex:0];
        linkURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            linkURL.text = url;
        }
        
        linkURL.rightView = am;
        linkURL.rightViewMode = UITextFieldViewModeAlways;
        
        UITextField *alt = [self.alertView textFieldAtIndex:1];
        alt.secureTextEntry = NO;
        alt.placeholder = NSLocalizedString(@"Title", nil);
        if (title) {
            alt.text = title;
        }
        
        [self.alertView show];
    }
    
}


- (void)insertLink:(NSString *)url title:(NSString *)title {
    
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}


- (void)updateLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)dismissAlertView {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
}

- (void)addCustomToolbarItemWithButton:(UIButton *)button
{
    if(self.customBarButtonItems == nil)
    {
        self.customBarButtonItems = [NSMutableArray array];
    }
    
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28.5f];
    [button setTitleColor:[self barButtonItemDefaultColor] forState:UIControlStateNormal];
    [button setTitleColor:[self barButtonItemSelectedDefaultColor] forState:UIControlStateHighlighted];
    
    ZSSBarButtonItem *barButtonItem = [[ZSSBarButtonItem alloc] initWithCustomView:button];
    
    [self.customBarButtonItems addObject:barButtonItem];
    
    [self buildToolbar];
}

- (void)addCustomToolbarItem:(ZSSBarButtonItem *)item {
    
    if(self.customZSSBarButtonItems == nil)
    {
        self.customZSSBarButtonItems = [NSMutableArray array];
    }
    [self.customZSSBarButtonItems addObject:item];
    
    [self buildToolbar];
}


- (void)removeLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.unlink();"];
}//end

- (void)quickLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.quickLink();"];
}

- (void)insertImage {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    [self showInsertImageDialogWithLink:self.selectedImageURL alt:self.selectedImageAlt];
    
}

- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertImageAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *imageURL = [alertController.textFields objectAtIndex:0];
            UITextField *alt = [alertController.textFields objectAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
            [self focusTextEditor];
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 1;
        UITextField *imageURL = [self.alertView textFieldAtIndex:0];
        imageURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            imageURL.text = url;
        }
        
        imageURL.rightView = am;
        imageURL.rightViewMode = UITextFieldViewModeAlways;
        imageURL.clearButtonMode = UITextFieldViewModeAlways;
        
        UITextField *alt1 = [self.alertView textFieldAtIndex:1];
        alt1.secureTextEntry = NO;
        alt1.placeholder = NSLocalizedString(@"Alt", nil);
        alt1.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            alt1.text = alt;
        }
        
        [self.alertView show];
    }
    
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateToolBarWithButtonName:(NSString *)name {
    
    // Items that are enabled
    NSArray *itemNames = [name componentsSeparatedByString:@","];
    
    // Special case for link
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
    for (NSString *linkItem in itemNames) {
        NSString *updatedItem = linkItem;
        if ([linkItem hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [linkItem stringByReplacingOccurrencesOfString:@"link:" withString:@""];
        } else if ([linkItem hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([linkItem hasPrefix:@"image:"]) {
            updatedItem = @"image";
            self.selectedImageURL = [linkItem stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([linkItem hasPrefix:@"image-alt:"]) {
            self.selectedImageAlt = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        } else {
            self.selectedImageURL = nil;
            self.selectedImageAlt = nil;
            self.selectedLinkURL = nil;
            self.selectedLinkTitle = nil;
        }
        [itemsModified addObject:updatedItem];
    }
    itemNames = [NSArray arrayWithArray:itemsModified];
    
    self.editorItemsEnabled = itemNames;
    
    // Highlight items
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if ([itemNames containsObject:item.label]) {
            item.tintColor = [self barButtonItemSelectedDefaultColor];
        } else {
            item.tintColor = [self barButtonItemDefaultColor];
        }
    }//end
    
}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *urlString = [[request URL] absoluteString];
    
    NSString *requestString = [urlString stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    if ([requestString hasPrefix:@"ios-log:"]) {
        NSString* logString = [[requestString componentsSeparatedByString:@":#iOS#"] objectAtIndex:1];
        NSLog(@"UIWebView console: %@", logString);
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    } else if ([urlString rangeOfString:@"callback://0/"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"callback://0/" withString:@""];
        [self updateToolBarWithButtonName:className];
        
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
        
    }
    else if ([urlString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [urlString componentsSeparatedByString:@":"];
        NSString *function = (NSString*)[components objectAtIndex:1];
        int callbackId = [((NSString*)[components objectAtIndex:2]) intValue];
        NSString *argsAsString = [[[(NSString*)[components objectAtIndex:3]
                                    stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                   stringByReplacingOccurrencesOfString:@"[" withString:@""] stringByReplacingOccurrencesOfString:@"]" withString:@""];
        NSArray *args = [argsAsString componentsSeparatedByString:@","];
        [self handleCall:function callbackId:callbackId args:args];
    }
    
    return YES;
    
}//end


// Implements all you native function in this one, by matching 'functionName' and parsing 'args'
// Use 'callbackId' with 'returnResult' selector when you get some results to send back to javascript
- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args
{
    if ([functionName isEqualToString:@"contentHeightDidChange"]) {
        
        if ([args count]!=3) {
            NSLog(@"contentHeightDidChange needs exactly 2 arguments!");
            return;
        }
        
        self.contentHeight = [[args objectAtIndex:0] integerValue];
        self.carrotPositionY = [[args objectAtIndex:1] integerValue];
        self.carrotRelativePositionY = [[args objectAtIndex:2] integerValue];

        if ([self.delegate respondsToSelector:@selector(richTextEditorViewDidChange:)]) {
            [self.delegate richTextEditorViewDidChange:self];
        }
        
    } else if ([functionName isEqualToString:@"editorDidBeginEditing"]) {
        
        if ([args count]!=3) {
            NSLog(@"editorDidBeginEditing needs exactly 2 arguments!");
            return;
        }
        
        self.contentHeight = [[args objectAtIndex:0] integerValue];
        self.carrotPositionY = [[args objectAtIndex:1] integerValue];
        self.carrotRelativePositionY = [[args objectAtIndex:2] integerValue];

        if ([self.delegate respondsToSelector:@selector(richTextEditorViewShouldBeginEditing:)]) {
            [self.delegate richTextEditorViewShouldBeginEditing:self];
        }
        
        if ([self.delegate respondsToSelector:@selector(richTextEditorViewDidBeginEditing:)]) {
            [self.delegate richTextEditorViewDidBeginEditing:self];
        }
        
    } else if ([functionName isEqualToString:@"updateCarretPosition"]) {
        
        if ([args count]!=2) {
            NSLog(@"updateCarretPosition needs exactly 1 arguments!");
            return;
        }
        
        self.carrotPositionY = [[args objectAtIndex:0] integerValue];
        self.carrotRelativePositionY = [[args objectAtIndex:1] integerValue];
        
    } else if ([functionName isEqualToString:@"updateContentHeight"]) {
        
        if ([args count]!=1) {
            NSLog(@"updateContentHeight needs exactly 1 arguments!");
            return;
        }
        
        self.contentHeight = [[args objectAtIndex:0] integerValue];
        
        if ([self.delegate respondsToSelector:@selector(richTextEditorViewHeightDidChange:)]) {
            [self.delegate richTextEditorViewHeightDidChange:self];
        }
        
    } else if ([functionName isEqualToString:@"editorDidEndEditing"]) {
        
        if ([self.delegate respondsToSelector:@selector(richTextEditorViewDidEndEditing:)]) {
            [self.delegate richTextEditorViewDidEndEditing:self];
        }
    }
}



- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.editorLoaded = YES;
    [self setPlaceholderText];
    if (!self.internalHTML) {
        self.internalHTML = @"";
    }
    [self updateHTML];
}

#pragma mark - Asset Picker

- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}


- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}


#pragma mark - Keyboard status

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    self.keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Toolbar Sizes
    CGFloat sizeOfToolbar = CGRectGetHeight(self.toolbarHolder.frame);
    
    CGRect keyboardEndInView = [self.view convertRect:self.keyboardEnd fromView:nil];
    
    CGFloat keyboardTopYInView = keyboardEndInView.origin.y;
    keyboardTopYInView = MAX(0, keyboardTopYInView);
    
    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
    BOOL isInFirstResponderChain = [UIResponder zss_isInResponderChain:self.view];
    
    if (isInFirstResponderChain && [notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        
        self.toolbarHolder.alpha = 0;
        
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            self.toolbarHolder.alpha = 1;
            
            // Toolbar
            CGRect frame = self.toolbarHolder.frame;
            frame.origin.y = self.keyboardEnd.origin.y - sizeOfToolbar;
            self.toolbarHolder.frame = frame;

            if (!self.editorView.scrollView.scrollEnabled) {
                self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
                self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            }
        } completion:nil];
        
    } else {
        
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            self.toolbarHolder.alpha = isInFirstResponderChain ? 1.0f : 0.0f;
            
            CGRect frame = self.toolbarHolder.frame;
            frame.origin.y = CGRectGetHeight([UIScreen mainScreen].bounds);
            self.toolbarHolder.frame = frame;
        } completion:nil];
        
    }//end
}

#pragma mark - Utilities

- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}//end


- (NSString *)tidyHTML:(NSString *)html {
    
    // remove p tag around unordered lists
    html = [html stringByReplacingOccurrencesOfString:@"<p><ul>" withString:@"<ul>"];
    html = [html stringByReplacingOccurrencesOfString:@"</ul></p>" withString:@"</ul>"];
    
    // remove p tag around ordered lists
    html = [html stringByReplacingOccurrencesOfString:@"<p><ol>" withString:@"<ol>"];
    html = [html stringByReplacingOccurrencesOfString:@"</ol></p>" withString:@"</ol>"];
    
    if (self.formatHTML) {
        html = [self.editorView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"style_html(\"%@\");", html]];
    }
    return html;
}//end


- (UIColor *)barButtonItemDefaultColor {
    
    if (self.toolbarItemTintColor) {
        return self.toolbarItemTintColor;
    }
    
    return [UIColor blackColor];
}


- (UIColor *)barButtonItemSelectedDefaultColor {
    
    if (self.toolbarItemSelectedTintColor) {
        return self.toolbarItemSelectedTintColor;
    }
    
    return [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}


- (BOOL)isIpad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}//end


- (NSString *)stringByDecodingURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}


- (void)enableToolbarItems:(BOOL)enable {
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if (![item.label isEqualToString:@"source"]) {
            item.enabled = enable;
        }
    }
}

#pragma mark - <UIScrollViewDelegate>
// Make sure the editorView doesn't scroll
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    scrollView.bounds = self.editorView.bounds;
}


@end
