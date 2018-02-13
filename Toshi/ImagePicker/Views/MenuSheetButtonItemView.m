#import "MenuSheetButtonItemView.h"
#import "ModernButton.h"
#import "Font.h"

#import "Common.h"
#import "Toshi-Swift.h"

const CGFloat MenuSheetButtonItemViewHeight = 57.0f;

@interface MenuSheetButtonItemView ()
{
    ModernButton *_button;
}

@end

@implementation MenuSheetButtonItemView


- (instancetype)initWithTitle:(NSString *)title type:(MenuSheetButtonType)type action:(void (^)(void))action
{
    self = [super initWithType:(type == MenuSheetButtonTypeCancel) ? MenuSheetItemTypeFooter : MenuSheetItemTypeDefault];
    if (self != nil)
    {
        self.action = action;
        _buttonType = type;
        
        _button = [[ModernButton alloc] init];
        _button.exclusiveTouch = true;
        _button.highlightBackgroundColor = UIColorRGB(0xebebeb);
        [self _updateForType:type];
        [_button setTitle:title forState:UIControlStateNormal];
        [_button setTitleColor:[Theme tintColor] forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        
        __weak MenuSheetButtonItemView *weakSelf = self;
        _button.highlitedChanged = ^(bool highlighted)
        {
            __strong MenuSheetButtonItemView *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf.highlightUpdateBlock != nil)
                strongSelf.highlightUpdateBlock(highlighted);
        };
    }
    return self;
}

- (void)buttonPressed
{
    if (self.action != nil)
        self.action();
}

- (void)buttonLongPressed
{
    if (self.longPressAction != nil)
        self.longPressAction();
}

- (void)setLongPressAction:(void (^)(void))longPressAction
{
    _longPressAction = [longPressAction copy];
    if (_longPressAction != nil)
    {
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed)];
        gestureRecognizer.minimumPressDuration = 0.4;
        [_button addGestureRecognizer:gestureRecognizer];
    }
}

- (NSString *)title
{
    return [_button titleForState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title
{
    [_button setTitle:title forState:UIControlStateNormal];
}

- (void)setButtonType:(MenuSheetButtonType)buttonType
{
    _buttonType = buttonType;
    [self _updateForType:buttonType];
}

- (void)_updateForType:(MenuSheetButtonType)type
{
    _button.titleLabel.font = (type == MenuSheetButtonTypeCancel || type == MenuSheetButtonTypeSend) ? TGMediumSystemFontOfSize(20) : TGSystemFontOfSize(20);
    [_button setTitleColor:(type == MenuSheetButtonTypeDestructive) ? TGDestructiveAccentColor() : TGAccentColor()];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)__unused width screenHeight:(CGFloat)__unused screenHeight
{
    return MenuSheetButtonItemViewHeight;
}

- (bool)requiresDivider
{
    return true;
}

- (void)layoutSubviews
{
    _button.frame = self.bounds;
}

@end
