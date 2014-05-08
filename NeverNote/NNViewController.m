//
//  NNViewController.m
//  NeverNote
//
//  Created by Nathan Fennel on 5/4/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNViewController.h"
#import <CoreMotion/CoreMotion.h>

// screen width
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

// screen height
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// status bar height
#define kStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

// Sizes 'n Stuff
#define FONT_SIZE 18.0f
#define KEYBOARD_HEIGHT 214.0f
#define TOOLBAR_HEIGHT 44.0f

// Background
#define BACKGROUND_TEXT @"NeverNote"
#define BACKGROUND_FONT_SIZE 22.0f
#define BACKGROUND_LABEL_ALPHA 0.4f

// Motion
#define KNOCK_ACCELERATION 5.0f
#define kFilteringFactor 0.1
float prevX;
float prevY;
float prevZ;
BOOL ONE_SHAKE = YES;

@interface NNViewController ()

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) NSString *oldText;

@property (nonatomic) float currentFontSize, tempFontSize;

@property (nonatomic) BOOL isDaylight, isUpdated, isClearing, bumpA, bumpB, bumpC, bumpD, bumpNet;

@property (nonatomic, strong) UIToolbar *keyboardToolbarUpperCaseDark, *keyboardToolbarLowerCaseDark, *keyboardToolbarUpperCaseLight, *keyboardToolbarLowerCaseLight;

@property (nonatomic, strong) NSDate *lastDoubleBump;

@property (nonatomic, strong) UILabel *resetLabelWarning, *labelForCopy, *pasteWarningLabel, *viewBackgroundLabel, *nightModeLabel, *dayModeLabel;

@end

@implementation NNViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentFontSize = FONT_SIZE;
        _isDaylight = [self isDaylight];
        _lastDoubleBump = [NSDate date];
        
        [self.view setBackgroundColor:(_isDaylight) ? [UIColor lightTextColor] : [UIColor darkGrayColor]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpStatusBar:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initStatusBar];
    [self setUpGestures];
    [self.view addSubview:self.viewBackgroundLabel];
    [self.view addSubview:self.textView];
    [self.viewBackgroundLabel setCenter:self.textView.center];
    [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:NO];
    [self setUpLabels];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startMotionDetect];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.textView setText:@""];
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.motionManager stopAccelerometerUpdates];
}

- (void)initStatusBar {
    [[UIApplication sharedApplication] setStatusBarStyle:(_isDaylight) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)setUpStatusBar:(NSNotification *)notification {
	[[UIApplication sharedApplication] setStatusBarStyle:(_isDaylight) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent];
    
    if (!([[UIDevice currentDevice] orientation] == UIDeviceOrientationIsLandscape(UIDeviceOrientationLandscapeLeft) || [[UIDevice currentDevice] orientation] == UIDeviceOrientationIsLandscape(UIDeviceOrientationLandscapeRight)) && _isUpdated) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
        [self.textView setInputAccessoryView:nil];
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(2, 2, 8, 2)];
        [_textView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width/2)];
        
    }
    
    else if ([UIApplication sharedApplication].statusBarHidden){
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
        [self.textView setInputAccessoryView:[self currentInputAccessoryView]];
        [_textView reloadInputViews];
        
        [_textView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - KEYBOARD_HEIGHT)];
        
        [_textView setCenter:CGPointMake(_textView.center.x, _textView.center.y + 20.0f)];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, _textView.inputAccessoryView.frame.size.height + 8, 2)];
    }
    
    [_viewBackgroundLabel setCenter:CGPointMake(_textView.center.x, _textView.center.y - _textView.inputAccessoryView.frame.size.height/2)];
}

- (void)setUpGestures {
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipeDown];
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipeUp];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinch];

    UIRotationGestureRecognizer *rot = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    [self.view addGestureRecognizer:rot];
}

- (void)setUpLabels {
    [self.view addSubview:self.resetLabelWarning];
    [self.view addSubview:self.labelForCopy];
    [self.view addSubview:self.pasteWarningLabel];
    [self.view addSubview:self.nightModeLabel];
    [self.view addSubview:self.dayModeLabel];
}

#pragma mark - Gesture Actions

- (void)swipeLeft {
    [self goForward];
}

- (void)swipeRight {
    [self goBack];
}

- (void)swipeDown {
    if ([_textView selectedRange].length > 0) {
        [_textView setSelectedTextRange:[_textView textRangeFromPosition:[_textView positionFromPosition:_textView.endOfDocument offset:0] toPosition:[_textView positionFromPosition:_textView.endOfDocument offset:0]]];
    }
    
    else {
        [self updateInputAccessory];
    }
    
    [self updateBackgroundLabelPosition];
}

- (void)swipeUp {
    [self selectAllText];
    
    if (_textView.text.length == 0) {
        [self updateInputAccessory];
    }
    
    else if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
        [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
        [_textView reloadInputViews];
    }
    
    else {
        [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
        [_textView reloadInputViews];
    }
    
    [self updateBackgroundLabelPosition];
}

#pragma mark - Input Accessory Views

- (void)updateInputAccessory {
    if (self.textView.inputAccessoryView) {
        [self.textView setInputAccessoryView:nil];
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, 8, 2)];
    }
    
    else {
        if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
            [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
        }
        
        else {
            [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
        }
        
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, _textView.inputAccessoryView.frame.size.height + 8, 2)];
    }
}

- (UIToolbar *)currentInputAccessoryView {
    if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
        if (_isDaylight) {
            return self.keyboardToolbarLowerCaseLight;
        }
        
        else {
            return self.keyboardToolbarLowerCaseDark;
        }
    }
    
    else {
        if (_isDaylight) {
            return self.keyboardToolbarUpperCaseLight;
        }
        
        else {
            return self.keyboardToolbarUpperCaseDark;
        }
    }
}

#pragma mark - Back/Forth Actions

- (void)goBack {
    if (![_textView.text isEqualToString:@""]) {
        _oldText = _textView.text;
        [_textView setText:@""];
    }
    
    else {
        [self resetView];
    }
}

- (void)goForward {
    if (![_textView.text isEqualToString:_oldText] && _oldText.length != 0) {
        NSString *tempText = _textView.text;
        [_textView setText:_oldText];
        _oldText = tempText;
    }
    
    else if ([[UIPasteboard generalPasteboard] string] != nil) {
        [_textView setText:[NSString stringWithFormat:@"%@%@",_textView.text,[[UIPasteboard generalPasteboard] string]]];
        [self animateLabel:_pasteWarningLabel];
    }
}

#pragma mark - Reset View

- (void)resetView {
    [_textView setInputAccessoryView:nil];
    [_textView setText:@""];
    [_textView setSelectedTextRange:[_textView textRangeFromPosition:[_textView positionFromPosition:_textView.beginningOfDocument inDirection:UITextLayoutDirectionRight offset:0] toPosition:_textView.beginningOfDocument]];
    [_textView setFont:[UIFont boldSystemFontOfSize:FONT_SIZE]];
    [_textView setBounces:YES];
    [_textView setKeyboardType:UIKeyboardTypeAlphabet];
    [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    [_textView setScrollsToTop:YES];
    [_textView setShowsVerticalScrollIndicator:NO];
    [_textView setBackgroundColor:[UIColor clearColor]];
    [_textView setTextColor:[UIColor lightTextColor]];
    [_textView setOpaque:NO];
    [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarUpperCaseLight];
    
    if (_isDaylight) {
        [_textView setKeyboardAppearance:UIKeyboardAppearanceLight];
        [_textView setTextColor:[UIColor blackColor]];
        [self.textView setInputAccessoryView:self.keyboardToolbarUpperCaseLight];
        if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
            [self.textView setInputAccessoryView:self.keyboardToolbarLowerCaseLight];
        }
    }
    _oldText = @"";
    
    [self.view setBackgroundColor:(_isDaylight) ? [UIColor lightTextColor] : [UIColor darkGrayColor]];
    
    if (!_isDaylight) {
        [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseDark : self.keyboardToolbarUpperCaseDark];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }
    
    else {
        [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarUpperCaseLight];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    }
    [_textView reloadInputViews];
    _isUpdated = YES;
}

#pragma mark - Select All/Copy

- (void)selectAllText {
    if (_textView.text.length > 0) {
        [[UIPasteboard generalPasteboard] setString:[_textView text]];
        [self animateLabel:_labelForCopy];
    }
}

#pragma mark - Pinch/Rotate Gesture

- (void)pinch:(UIPinchGestureRecognizer *)sender {
    if (sender.scale > 1) {
        _tempFontSize = _currentFontSize + sender.scale;
        [_textView setFont:[UIFont boldSystemFontOfSize:_tempFontSize]];
    }
    
    else if (sender.scale < 1) {
        _tempFontSize = _currentFontSize - (1/sender.scale);
        [_textView setFont:[UIFont boldSystemFontOfSize:_tempFontSize]];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        _currentFontSize = _tempFontSize;
    }
}

- (void)rotate:(UIRotationGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.rotation > 0) {
        [self.textView setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    }
    
    else if (sender.state == UIGestureRecognizerStateBegan && sender.rotation < 0) {
        [self.textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    }
}

#pragma mark - Text View

- (UITextView *)textView {
    if (!_textView) {
        float yPos = ([[UIApplication sharedApplication] statusBarFrame].size.height <= 20.0f) ? [[UIApplication sharedApplication] statusBarFrame].size.height : 20.0f;
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, yPos, kScreenWidth, kScreenHeight - yPos - KEYBOARD_HEIGHT)];
        [_textView setFont:[UIFont boldSystemFontOfSize:FONT_SIZE]];
        [_textView setBounces:YES];
        [_textView setKeyboardType:UIKeyboardTypeDefault];
        [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
        [_textView setScrollsToTop:YES];
        [_textView setShowsVerticalScrollIndicator:NO];
        [_textView setBackgroundColor:[UIColor clearColor]];
        [_textView setTextColor:[UIColor lightTextColor]];
        [_textView setOpaque:NO];
        [_textView setScrollsToTop:YES];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, TOOLBAR_HEIGHT + 8, 2)];
        
        if (_isDaylight) {
            [_textView setKeyboardAppearance:UIKeyboardAppearanceLight];
            [_textView setTextColor:[UIColor blackColor]];
        }
    }
    
    return _textView;
}

#pragma mark - Keyboard Toolbar

- (UIToolbar *)keyboardToolbarUpperCaseLight {
    if (!_keyboardToolbarUpperCaseLight) {
        _keyboardToolbarUpperCaseLight = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarUpperCaseLight setBackgroundColor:[UIColor clearColor]];
        [_keyboardToolbarUpperCaseLight setTranslucent:YES];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = @[@"ABC",@"@",@"#",@"12p"];
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStyleBordered target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:25.0/255.0 green:4.0/255.0 blue:100.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSBackgroundColorAttributeName,
                                            shadow, NSShadowAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil] 
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarUpperCaseLight setItems:toolbarItems];
    }
    
    return _keyboardToolbarUpperCaseLight;
}

- (UIToolbar *)keyboardToolbarLowerCaseLight {
    if (!_keyboardToolbarLowerCaseLight) {
        _keyboardToolbarLowerCaseLight = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarLowerCaseLight setBackgroundColor:[UIColor clearColor]];
        [_keyboardToolbarLowerCaseLight setTranslucent:YES];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = @[@"abc",@"@",@"#",@"12p"];
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStyleBordered target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:25.0/255.0 green:4.0/255.0 blue:100.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSBackgroundColorAttributeName,
                                            shadow, NSShadowAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarLowerCaseLight setItems:toolbarItems];
    }
    
    return _keyboardToolbarLowerCaseLight;
}

- (UIToolbar *)keyboardToolbarUpperCaseDark {
    if (!_keyboardToolbarUpperCaseDark) {
        _keyboardToolbarUpperCaseDark = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarUpperCaseDark setBarTintColor:[UIColor blackColor]];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = @[@"ABC",@"@",@"#",@"12p"];
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStyleBordered target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:205.0/255.0 green:204.0/255.0 blue:200.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarUpperCaseDark setItems:toolbarItems];
    }
    
    return _keyboardToolbarUpperCaseDark;
}

- (UIToolbar *)keyboardToolbarLowerCaseDark {
    if (!_keyboardToolbarLowerCaseDark) {
        _keyboardToolbarLowerCaseDark = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarLowerCaseDark setBarTintColor:[UIColor blackColor]];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = @[@"abc",@"@",@"#",@"12p"];
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStyleBordered target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:205.0/255.0 green:204.0/255.0 blue:200.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarLowerCaseDark setItems:toolbarItems];
    }
    
    return _keyboardToolbarLowerCaseDark;
}

#pragma mark - Labels

- (UILabel *)resetLabelWarning {
    if (!_resetLabelWarning) {
        _resetLabelWarning = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_resetLabelWarning setText:@"Reset"];
        [_resetLabelWarning setTextAlignment:NSTextAlignmentCenter];
        [_resetLabelWarning setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _resetLabelWarning;
}

- (UILabel *)labelForCopy {
    if (!_labelForCopy) {
        _labelForCopy = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_labelForCopy setText:@"Copied to clipboard"];
        [_labelForCopy setTextAlignment:NSTextAlignmentCenter];
        [_labelForCopy setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _labelForCopy;
}

- (UILabel *)pasteWarningLabel {
    if (!_pasteWarningLabel) {
        _pasteWarningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_pasteWarningLabel setText:@"Paste"];
        [_pasteWarningLabel setTextAlignment:NSTextAlignmentCenter];
        [_pasteWarningLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _pasteWarningLabel;
}

-(UILabel *)nightModeLabel {
    if (!_nightModeLabel) {
        _nightModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_nightModeLabel setText:@"Night Mode"];
        [_nightModeLabel setTextAlignment:NSTextAlignmentCenter];
        [_nightModeLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
        [_nightModeLabel setTextColor:[UIColor yellowColor]];
    }
    
    return _nightModeLabel;
}

- (UILabel *)dayModeLabel {
    if (!_dayModeLabel) {
        _dayModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_dayModeLabel setText:@"Day Mode"];
        [_dayModeLabel setTextAlignment:NSTextAlignmentCenter];
        [_dayModeLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _dayModeLabel;
}

- (UILabel *)viewBackgroundLabel {
	if (!_viewBackgroundLabel) {
		_viewBackgroundLabel = [[UILabel alloc] init];
		
		UIFont *font = [UIFont boldSystemFontOfSize:BACKGROUND_FONT_SIZE];
		
		UIColor *textColor = [UIColor colorWithWhite:0.8 alpha:0.9];
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setAlignment:NSTextAlignmentCenter];
		
		NSDictionary *attrs = @{NSForegroundColorAttributeName : textColor,
								NSFontAttributeName : font,
								NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
								NSParagraphStyleAttributeName: paragraphStyle};
		
		NSAttributedString *attrString = [[NSAttributedString alloc]
										  initWithString:BACKGROUND_TEXT
										  attributes:attrs];
		
		[_viewBackgroundLabel setAttributedText:attrString];
		
		CGRect textRect = [attrString boundingRectWithSize:self.view.bounds.size options:0 context:nil];
		
		CGRect integralTextRect = CGRectIntegral(textRect);
		
		[_viewBackgroundLabel setFrame:CGRectMake((kScreenWidth)/2, (kScreenHeight - KEYBOARD_HEIGHT)/2 - TOOLBAR_HEIGHT/2, integralTextRect.size.width, integralTextRect.size.height)];
        
        [_viewBackgroundLabel setAlpha:BACKGROUND_LABEL_ALPHA];
	}
	
	return _viewBackgroundLabel;
}

- (void)animateLabel:(UILabel *)label {
    [UILabel setAnimationBeginsFromCurrentState:YES];
    [label setCenter:_viewBackgroundLabel.center];
    [label setAlpha:0.0f];
    [label setTextColor:(_isDaylight) ? [UIColor darkGrayColor] : [UIColor whiteColor]];
    [UILabel animateWithDuration:0.5f animations:^{
        [label setCenter:CGPointMake(label.center.x, label.center.y + 10.0f)];
        [label setAlpha:0.5f];
        [_viewBackgroundLabel setAlpha:0.07f];
    }completion:^(BOOL finished){
        [UILabel animateWithDuration:0.5f animations:^{
            [label setCenter:CGPointMake(label.center.x, label.center.y + 10.0f)];
            [label setAlpha:0.0f];
            [_viewBackgroundLabel setAlpha:BACKGROUND_LABEL_ALPHA];
        }];
    }];
}

- (void)updateBackgroundLabelPosition {
    [UILabel animateWithDuration:0.33 animations:^{
        [_viewBackgroundLabel setCenter:CGPointMake(_viewBackgroundLabel.center.x, _textView.center.y - _textView.inputAccessoryView.bounds.size.height/2)];
    }];
}

#pragma mark - Change Keyboard Type

- (void)changeKeyboard:(UIBarButtonItem *)sender {
    switch (sender.tag) {
        case 10:
            if (_textView.keyboardType == UIKeyboardTypeAlphabet) {
                [_textView setKeyboardType:UIKeyboardTypeNamePhonePad];
                [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
                [_textView reloadInputViews];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeAlphabet];
                [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
                [_textView reloadInputViews];
            }
            break;
            
        case 11:
            if (_textView.keyboardType != UIKeyboardTypeEmailAddress) {
                [_textView setKeyboardType:UIKeyboardTypeEmailAddress];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeTwitter];
            }
            break;
            
        case 12:
            if (_textView.keyboardType != UIKeyboardTypeDecimalPad) {
                [_textView setKeyboardType:UIKeyboardTypeDecimalPad];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeNumberPad];
            }
            break;
            
        case 13:
            [_textView setKeyboardType:UIKeyboardTypeNumberPad];
            break;
            
        default:
            break;
    }
    [self updateKeyboard];
}

- (void)updateKeyboard {
    [_textView resignFirstResponder];
    [_textView becomeFirstResponder];
}

#pragma mark - Motion Detection

- (void)startMotionDetect
{
    [self.motionManager
     startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMAccelerometerData *data, NSError *error)
     {
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            int x = abs(self.motionManager.accelerometerData.acceleration.x);
                            int y = abs(self.motionManager.accelerometerData.acceleration.y);
                            int z = abs(self.motionManager.accelerometerData.acceleration.z);
                            
                            if (ONE_SHAKE) {
                                if (x + y + z > KNOCK_ACCELERATION && _textView.text.length > 0) {
                                    [self resetView];
                                    [self animateLabel:_resetLabelWarning];
                                    _isClearing = YES;
                                }
                                
                                else if (x + y + z > KNOCK_ACCELERATION && _isUpdated && !_isClearing) {
                                    if (_isDaylight) {
                                        _isDaylight = NO;
                                        [self animateLabel:_nightModeLabel];
                                    }
                                    
                                    else {
                                        _isDaylight = YES;
                                        [self animateLabel:_dayModeLabel];
                                    }
                                    _isUpdated = NO;
                                }
                                
                                else if (x + y + z < 0.3 && !_isUpdated) {
                                    [self resetView];
                                }
                                
                                else if (x + y + z < 0.3 && _isClearing) {
                                    _isClearing = NO;
                                }
                            }
                            
                            else {
                                if (x + y + z > KNOCK_ACCELERATION) {
                                    // Isolate Instantaneous Motion from Acceleration Data
                                    // (using a simplified high-pass filter)
                                    CMAcceleration acceleration = data.acceleration;
                                    float prevAccelX = prevX;
                                    float prevAccelY = prevY;
                                    float prevAccelZ = prevZ;
                                    prevX = acceleration.x - ( (acceleration.x * kFilteringFactor) +
                                                              (prevX * (1.0 - kFilteringFactor)) );
                                    prevY = acceleration.y - ( (acceleration.y * kFilteringFactor) +
                                                              (prevY * (1.0 - kFilteringFactor)) );
                                    prevZ = acceleration.z - ( (acceleration.z * kFilteringFactor) +
                                                              (prevZ * (1.0 - kFilteringFactor)) );
                                    
                                    // Compute the derivative (which represents change in acceleration).
                                    float deltaX = ABS((prevX - prevAccelX));
                                    float deltaY = ABS((prevY - prevAccelY));
                                    float deltaZ = ABS((prevZ - prevAccelZ));
                                    
                                    // Check if the derivative exceeds some sensitivity threshold
                                    // (Bigger value indicates stronger bump)
                                    // (Probably should use length of the vector instead of componentwise)
                                    if ((deltaX > 1 || deltaY > 1 || deltaZ > 1)) {
                                        _bumpNet = YES;
                                    }
                                    
                                    else {
                                        _bumpNet = NO;
                                    }
                                    
                                    if (!_bumpB && !_bumpC && !_bumpD && _bumpNet) {
                                        _bumpA = YES;
                                    }
                                    
                                    else if (_bumpA && !_bumpC && !_bumpD && !_bumpNet) {
                                        _bumpB = YES;
                                    }
                                    
                                    else if (_bumpA && _bumpB && !_bumpD && _bumpNet) {
                                        _bumpC = YES;
                                        if (abs([_lastDoubleBump timeIntervalSinceNow]) > 1.5) {
                                            _bumpA = NO;
                                            _bumpB = NO;
                                            _bumpC = NO;
                                            _bumpD = NO;
                                            _lastDoubleBump = [NSDate date];
                                        }
                                    }
                                    
                                    else if (_bumpA && _bumpB && _bumpC && !_bumpNet) {
                                        _bumpD = YES;
                                    }
                                    
                                    if (_bumpA && _bumpB && _bumpC && _bumpD) {
                                        if (abs([_lastDoubleBump timeIntervalSinceNow]) > 0.5) {
                                            _bumpA = NO;
                                            _bumpB = NO;
                                            _bumpC = NO;
                                            _bumpD = NO;
                                            _lastDoubleBump = [NSDate date];
                                            
                                            if (_textView.text.length == 0) {
                                                if (_isDaylight) {
                                                    _isDaylight = NO;
                                                    [self animateLabel:_nightModeLabel];
                                                }
                                                
                                                else {
                                                    _isDaylight = YES;
                                                    [self animateLabel:_dayModeLabel];
                                                }
                                            }
                                            
                                            [self resetView];
                                        }
                                    }
                                }
                            }
                            
                            
                        });
     }];
}

- (CMMotionManager *)motionManager {
    CMMotionManager *motionManager = nil;
    
    id appDelegate = [UIApplication sharedApplication].delegate;
    
    if ([appDelegate respondsToSelector:@selector(motionManager)]) {
        motionManager = [appDelegate motionManager];
    }
    
    return motionManager;
}

#pragma mark - Is it daylight

- (BOOL)isDaylight {
    NSString *ds1 = @"07:00:00";
    NSString *ds2 = @"21:00:00";
    
    // parse given dates into NSDate objects
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    NSDate *date1 = [df dateFromString:ds1];
    NSDate *date2 = [df dateFromString:ds2];
    
    // get time interval from earlier to later given date
    NSDate *earlierDate = date1;
    NSTimeInterval ti = [date2 timeIntervalSinceDate:date1];
    
    if (ti < 0) {
        earlierDate = date2;
        ti = [date1 timeIntervalSinceDate:date2];
    }
    
    // get current date/time
    NSDate *now = [NSDate date];
    
    // create an NSDate for today at the earlier given time
    NSDateComponents *todayDateComps = [[NSCalendar currentCalendar]
                                        components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                        fromDate:now];
    NSDateComponents *earlierTimeComps = [[NSCalendar currentCalendar]
                                          components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
                                          fromDate:earlierDate];
    NSDateComponents *todayEarlierTimeComps = [[NSDateComponents alloc] init];
    [todayEarlierTimeComps setYear:[todayDateComps year]];
    [todayEarlierTimeComps setMonth:[todayDateComps month]];
    [todayEarlierTimeComps setDay:[todayDateComps day]];
    [todayEarlierTimeComps setHour:[earlierTimeComps hour]];
    [todayEarlierTimeComps setMinute:[earlierTimeComps minute]];
    [todayEarlierTimeComps setSecond:[earlierTimeComps second]];
    NSDate *todayEarlierTime = [[NSCalendar currentCalendar]
                                dateFromComponents:todayEarlierTimeComps];
    
    // create an NSDate for yesterday at the earlier given time
    NSDateComponents *minusOneDayComps = [[NSDateComponents alloc] init];
    [minusOneDayComps setDay:-1];
    NSDate *yesterday = [[NSCalendar currentCalendar]
                         dateByAddingComponents:minusOneDayComps
                         toDate:now
                         options:0];
    NSDateComponents *yesterdayDateComps = [[NSCalendar currentCalendar]
                                            components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                            fromDate:yesterday];
    NSDateComponents *yesterdayEarlierTimeComps = [[NSDateComponents alloc] init];
    [yesterdayEarlierTimeComps setYear:[yesterdayDateComps year]];
    [yesterdayEarlierTimeComps setMonth:[yesterdayDateComps month]];
    [yesterdayEarlierTimeComps setDay:[yesterdayDateComps day]];
    [yesterdayEarlierTimeComps setHour:[earlierTimeComps hour]];
    [yesterdayEarlierTimeComps setMinute:[earlierTimeComps minute]];
    [yesterdayEarlierTimeComps setSecond:[earlierTimeComps second]];
    NSDate *yesterdayEarlierTime = [[NSCalendar currentCalendar]
                                    dateFromComponents:yesterdayEarlierTimeComps];
    
    // check time interval from [today at the earlier given time] to [now]
    NSTimeInterval ti_todayEarlierTimeTillNow = [now timeIntervalSinceDate:todayEarlierTime];
    
    if (0 <= ti_todayEarlierTimeTillNow && ti_todayEarlierTimeTillNow <= ti) {
        return YES;
    }
    
    // check time interval from [yesterday at the earlier given time] to [now]
    NSTimeInterval ti_yesterdayEarlierTimeTillNow = [now timeIntervalSinceDate:yesterdayEarlierTime];
    
    if (0 <= ti_yesterdayEarlierTimeTillNow && ti_yesterdayEarlierTimeTillNow <= ti) {
        return YES;
    }
    
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated. If I have to.
}


@end
