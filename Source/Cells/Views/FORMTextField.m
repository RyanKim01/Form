#import "FORMTextField.h"

#import "FORMTextFieldCell.h"

#import "FORMTextFieldTypeManager.h"

@import Hex;

static const CGFloat FORMTextFieldClearButtonWidth = 30.0f;
static const CGFloat FORMTextFieldClearButtonHeight = 20.0f;
static const CGFloat FORMTextFieldMinusButtonWidth = 30.0f;
static const CGFloat FORMTextFieldMinusButtonHeight = 20.0f;
static const CGFloat FORMTextFieldPlusButtonWidth = 30.0f;
static const CGFloat FORMTextFieldPlusButtonHeight = 20.0f;

static UIColor *activeBackgroundColor;
static UIColor *activeBorderColor;
static UIColor *inactiveBackgroundColor;
static UIColor *inactiveBorderColor;

static UIColor *enabledBackgroundColor;
static UIColor *enabledBorderColor;
static UIColor *enabledTextColor;
static UIColor *disabledBackgroundColor;
static UIColor *disabledBorderColor;
static UIColor *disabledTextColor;

static UIColor *validBackgroundColor;
static UIColor *validBorderColor;
static UIColor *invalidBackgroundColor;
static UIColor *invalidBorderColor;

static BOOL enabledProperty;

@interface FORMTextField () <UITextFieldDelegate>

@property (nonatomic, getter = isModified) BOOL modified;
@property (nonatomic, retain) UIButton *clearButton;
@property (nonatomic, retain) UIButton *minusButton;
@property (nonatomic, retain) UIButton *plusButton;

@end

@implementation FORMTextField

@synthesize rawText = _rawText;

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.delegate = self;

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, FORMFieldCellLeftMargin, 0.0f)];
    self.leftView = paddingView;
    self.leftViewMode = UITextFieldViewModeAlways;

    [self addTarget:self action:@selector(textFieldDidUpdate:) forControlEvents:UIControlEventEditingChanged];
    [self addTarget:self action:@selector(textFieldDidReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];

    self.returnKeyType = UIReturnKeyDone;

    [self createClearButton];
    [self addClearButton];
    [self createCountButtons];

    return self;
}

#pragma mark - Setters

- (NSRange)currentRange {
    NSInteger startOffset = [self offsetFromPosition:self.beginningOfDocument
                                          toPosition:self.selectedTextRange.start];
    NSInteger endOffset = [self offsetFromPosition:self.beginningOfDocument
                                        toPosition:self.selectedTextRange.end];
    NSRange range = NSMakeRange(startOffset, endOffset-startOffset);

    return range;
}

- (void)setText:(NSString *)text {
    UITextRange *textRange = self.selectedTextRange;
    NSString *newRawText = [self.formatter formatString:text
                                                reverse:YES];
    NSRange range = [self currentRange];

    BOOL didAddText  = (newRawText.length > self.rawText.length);
    BOOL didFormat   = (text.length > super.text.length);
    BOOL cursorAtEnd = (newRawText.length == range.location);

    if ((didAddText && didFormat) || (didAddText && cursorAtEnd)) {
        self.selectedTextRange = textRange;
        [super setText:text];
    } else {
        [super setText:text];
        self.selectedTextRange = textRange;
    }
}

- (void)setRawText:(NSString *)rawText {
    BOOL shouldFormat = (self.formatter && (rawText.length >= _rawText.length ||
                                            ![rawText isEqualToString:_rawText]));

    if (shouldFormat) {
        self.text = [self.formatter formatString:rawText reverse:NO];
    } else {
        self.text = rawText;
    }

    _rawText = rawText;
}

- (void)setTypeString:(NSString *)typeString {
    _typeString = typeString;
    
    FORMTextFieldType type;
    if ([typeString isEqualToString:@"name"]) {
        type = FORMTextFieldTypeName;
    } else if ([typeString isEqualToString:@"username"]) {
        type = FORMTextFieldTypeUsername;
    } else if ([typeString isEqualToString:@"phone"]) {
        type = FORMTextFieldTypePhoneNumber;
    } else if ([typeString isEqualToString:@"number"]) {
        type = FORMTextFieldTypeNumber;
    } else if ([typeString isEqualToString:@"float"]) {
        type = FORMTextFieldTypeFloat;
    } else if ([typeString isEqualToString:@"address"]) {
        type = FORMTextFieldTypeAddress;
    } else if ([typeString isEqualToString:@"email"]) {
        type = FORMTextFieldTypeEmail;
    } else if ([typeString isEqualToString:@"date"]) {
        type = FORMTextFieldTypeDate;
    } else if ([typeString isEqualToString:@"select"]) {
        type = FORMTextFieldTypeSelect;
    } else if ([typeString isEqualToString:@"text"]) {
        type = FORMTextFieldTypeDefault;
    } else if ([typeString isEqualToString:@"password"]) {
        type = FORMTextFieldTypePassword;
    } else if ([typeString isEqualToString:@"count"]) {
        type = FORMTextFieldTypeCount;
        [self addCountButtons];
    } else if (!typeString.length) {
        type = FORMTextFieldTypeDefault;
    } else {
        type = FORMTextFieldTypeUnknown;
    }

    self.type = type;
}

- (void)setInputTypeString:(NSString *)inputTypeString {
    _inputTypeString = inputTypeString;

    FORMTextFieldInputType inputType;
    if ([inputTypeString isEqualToString:@"name"]) {
        inputType = FORMTextFieldInputTypeName;
    } else if ([inputTypeString isEqualToString:@"username"]) {
        inputType = FORMTextFieldInputTypeUsername;
    } else if ([inputTypeString isEqualToString:@"phone"]) {
        inputType = FORMTextFieldInputTypePhoneNumber;
    } else if ([inputTypeString isEqualToString:@"number"]) {
        inputType = FORMTextFieldInputTypeNumber;
    } else if ([inputTypeString isEqualToString:@"float"]) {
        inputType = FORMTextFieldInputTypeFloat;
    } else if ([inputTypeString isEqualToString:@"address"]) {
        inputType = FORMTextFieldInputTypeAddress;
    } else if ([inputTypeString isEqualToString:@"email"]) {
        inputType = FORMTextFieldInputTypeEmail;
    } else if ([inputTypeString isEqualToString:@"text"]) {
        inputType = FORMTextFieldInputTypeDefault;
    } else if ([inputTypeString isEqualToString:@"password"]) {
        inputType = FORMTextFieldInputTypePassword;
    } else if ([inputTypeString isEqualToString:@"count"]) {
        inputType = FORMTextFieldInputTypeCount;
    } else if (!inputTypeString.length) {
        inputType = FORMTextFieldInputTypeDefault;
    } else {
        inputType = FORMTextFieldInputTypeUnknown;
    }

    self.inputType = inputType;
}

- (void)setInputType:(FORMTextFieldInputType)inputType {
    _inputType = inputType;

    FORMTextFieldTypeManager *typeManager = [FORMTextFieldTypeManager new];
    [typeManager setUpType:inputType forTextField:self];
}

#pragma mark - Getters

- (NSString *)rawText {
    if (self.formatter) {
        return [self.formatter formatString:_rawText reverse:YES];
    }

    return _rawText;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(FORMTextField *)textField {
    BOOL selectable = (textField.type == FORMTextFieldTypeSelect ||
                       textField.type == FORMTextFieldTypeDate);

    if (selectable &&
        [self.textFieldDelegate respondsToSelector:@selector(textFormFieldDidBeginEditing:)]) {
        [self.textFieldDelegate textFormFieldDidBeginEditing:self];
    }

    return !selectable;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.active = YES;
    self.modified = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.active = NO;
    if ([self.textFieldDelegate respondsToSelector:@selector(textFormFieldDidEndEditing:)]) {
        [self.textFieldDelegate textFormFieldDidEndEditing:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (!string || [string isEqualToString:@"\n"]) return YES;

    BOOL validator = (self.inputValidator &&
                      [self.inputValidator respondsToSelector:@selector(validateReplacementString:withText:withRange:)]);

    if (validator) return [self.inputValidator validateReplacementString:string
                                                                withText:self.rawText withRange:range];

    return YES;
}

#pragma mark - UIResponder Overwritables

- (BOOL)becomeFirstResponder {
    if ([self.textFieldDelegate respondsToSelector:@selector(textFormFieldDidBeginEditing:)]) {
        [self.textFieldDelegate textFormFieldDidBeginEditing:self];
    }

    return [super becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    BOOL isTextField = (self.type != FORMTextFieldTypeSelect &&
                        self.type != FORMTextFieldTypeDate);

    return (isTextField && self.enabled) ?: [super canBecomeFirstResponder];
}

#pragma mark - Notifications

- (void)textFieldDidUpdate:(UITextField *)textField {
    if (!self.isValid) {
        self.valid = YES;
    }

    self.modified = YES;
    self.rawText = self.text;

    if ([self.textFieldDelegate respondsToSelector:@selector(textFormField:didUpdateWithText:)]) {
        [self.textFieldDelegate textFormField:self
                            didUpdateWithText:self.rawText];
    }
}

- (void)textFieldDidReturn:(UITextField *)textField {
    if ([self.textFieldDelegate respondsToSelector:@selector(textFormFieldDidReturn:)]) {
        [self.textFieldDelegate textFormFieldDidReturn:self];
    }
}

#pragma mark - Buttons

- (void)createCountButtons {
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"Form.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath: bundlePath];

    UITraitCollection *trait = [UITraitCollection traitCollectionWithDisplayScale:2.0];

    // Minus Button
    UIImage *minusImage = [UIImage imageNamed:@"minus" inBundle:bundle compatibleWithTraitCollection:trait];
    UIImage *minusImageTemplate = [minusImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.minusButton setImage:minusImageTemplate forState:UIControlStateNormal];
    
    [self.minusButton addTarget:self action:@selector(minusButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.minusButton.frame = CGRectMake(0.0f, 0.0f, FORMTextFieldMinusButtonWidth, FORMTextFieldMinusButtonHeight);

    // Plus Button
    UIImage *plusImage = [UIImage imageNamed:@"plus" inBundle:bundle compatibleWithTraitCollection:trait];
    UIImage *plusImageTemplate = [plusImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.plusButton setImage:plusImageTemplate forState:UIControlStateNormal];
    
    [self.plusButton addTarget:self action:@selector(plusButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.plusButton.frame = CGRectMake(0.0f, 0.0f, FORMTextFieldPlusButtonWidth, FORMTextFieldPlusButtonHeight);
}

- (void)addCountButtons {
    self.leftView = self.minusButton;
    self.leftViewMode = UITextFieldViewModeAlways;

    self.rightView = self.plusButton;
    self.rightViewMode = UITextFieldViewModeAlways;

    self.textAlignment = NSTextAlignmentCenter;
}

- (void)createClearButton {
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"Form.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath: bundlePath];
    
    UITraitCollection *trait = [UITraitCollection traitCollectionWithDisplayScale:2.0];

    UIImage *clearImage = [UIImage imageNamed:@"clear" inBundle:bundle compatibleWithTraitCollection:trait];
    UIImage *clearImageTemplate = [clearImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.clearButton setImage:clearImageTemplate forState:UIControlStateNormal];
    
    [self.clearButton addTarget:self action:@selector(clearButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.clearButton.frame = CGRectMake(0.0f, 0.0f, FORMTextFieldClearButtonWidth, FORMTextFieldClearButtonHeight);
}

- (void)addClearButton {
    self.rightView = self.clearButton;
    self.rightViewMode = UITextFieldViewModeWhileEditing;
}

#pragma mark - Actions

- (void)clearButtonAction {
    self.rawText = nil;

    if ([self.textFieldDelegate respondsToSelector:@selector(textFormField:didUpdateWithText:)]) {
        [self.textFieldDelegate textFormField:self
                            didUpdateWithText:self.rawText];
    }
}

- (void)minusButtonAction {
    NSNumber *number = @([self.rawText integerValue] - 1);
    if ([number integerValue] < 0) {
        self.rawText = @"0";
    } else {
        self.rawText = [number stringValue];
    }

    if ([self.textFieldDelegate respondsToSelector:@selector(textFormField:didUpdateWithText:)]) {
	[self.textFieldDelegate textFormField:self
			    didUpdateWithText:self.rawText];
    }
}

- (void)plusButtonAction {
    NSNumber *number = @([self.rawText integerValue] + 1);
    self.rawText = [number stringValue];

    if ([self.textFieldDelegate respondsToSelector:@selector(textFormField:didUpdateWithText:)]) {
	[self.textFieldDelegate textFormField:self
			    didUpdateWithText:self.rawText];
    }
}

#pragma mark - Appearance

- (void)setActive:(BOOL)active {
    _active = active;

    if (active) {
        self.backgroundColor = activeBackgroundColor;
        self.layer.borderColor = activeBorderColor.CGColor;
    } else {
        self.backgroundColor = inactiveBackgroundColor;
        self.layer.borderColor = inactiveBorderColor.CGColor;
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];

    enabledProperty = enabled;

    if (enabled) {
        self.backgroundColor = enabledBackgroundColor;
        self.layer.borderColor = enabledBorderColor.CGColor;
        self.textColor = enabledTextColor;
    } else {
        self.backgroundColor = disabledBackgroundColor;
        self.layer.borderColor = disabledBorderColor.CGColor;
        self.textColor = disabledTextColor;
    }
}

- (void)setValid:(BOOL)valid {
    _valid = valid;

    if (!self.isEnabled) return;

    if (valid) {
        self.backgroundColor = validBackgroundColor;
        self.layer.borderColor = validBorderColor.CGColor;
    } else {
        self.backgroundColor = invalidBackgroundColor;
        self.layer.borderColor = invalidBorderColor.CGColor;
    }
}

- (void)setCustomFont:(UIFont *)font {
    NSString *styleFont = [self.styles valueForKey:@"font"];
    NSString *styleFontSize = [self.styles valueForKey:@"font_size"];
    if ([styleFont length] > 0) {
        if ([styleFontSize length] > 0) {
            font = [UIFont fontWithName:styleFont size:[styleFontSize floatValue]];
        } else {
            font = [UIFont fontWithName:styleFont size:font.pointSize];
        }
    }
    self.font = font;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    NSString *style = [self.styles valueForKey:@"border_width"];
    if ([style length] > 0) {
        borderWidth = [style floatValue];
    }
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    NSString *style = [self.styles valueForKey:@"border_color"];
    if ([style length] > 0) {
        borderColor = [UIColor colorFromHex:style];
    }
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    NSString *style = [self.styles valueForKey:@"corner_radius"];
    if ([style length] > 0) {
        cornerRadius = [style floatValue];
    }
    self.layer.cornerRadius = cornerRadius;
}

- (void)setActiveBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"active_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    activeBackgroundColor = color;
}

- (void)setActiveBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"active_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    activeBorderColor = color;
}

- (void)setInactiveBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"inactive_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    inactiveBackgroundColor = color;
}

- (void)setInactiveBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"inactive_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    inactiveBorderColor = color;
}

- (void)setEnabledBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"enabled_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    enabledBackgroundColor = color;
}

- (void)setEnabledBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"enabled_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    enabledBorderColor = color;
}

- (void)setEnabledTextColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"enabled_text_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    enabledTextColor = color;
}

- (void)setDisabledBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"disabled_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    disabledBackgroundColor = color;
}

- (void)setDisabledBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"disabled_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    disabledBorderColor = color;
}

- (void)setDisabledTextColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"disabled_text_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    disabledTextColor = color;
    self.enabled = enabledProperty;
}

- (void)setValidBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"valid_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    validBackgroundColor = color;
}

- (void)setValidBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"valid_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    validBorderColor = color;
}

- (void)setInvalidBackgroundColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"invalid_background_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    invalidBackgroundColor = color;
}

- (void)setInvalidBorderColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"invalid_border_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    invalidBorderColor = color;
    self.enabled = enabledProperty;
}

- (void)setClearButtonColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"clear_button_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    self.clearButton.tintColor = color;
}

- (void)setMinusButtonColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"minus_button_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    self.minusButton.tintColor = color;
}

- (void)setPlusButtonColor:(UIColor *)color {
    NSString *style = [self.styles valueForKey:@"plus_button_color"];
    if ([style length] > 0) {
        color = [UIColor colorFromHex:style];
    }
    self.plusButton.tintColor = color;
}

@end
