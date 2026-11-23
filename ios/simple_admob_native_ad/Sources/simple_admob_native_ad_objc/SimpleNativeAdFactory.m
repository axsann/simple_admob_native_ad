#import "SimpleNativeAdFactory.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <google_mobile_ads/FLTGoogleMobileAdsPlugin.h>

// Swift Package Manager puts the target's resources in their own bundle and force-includes
// a generated header that defines SWIFTPM_MODULE_BUNDLE. CocoaPods copies them next to the
// class instead, so fall back to the class bundle when the macro is absent.
#ifndef SWIFTPM_MODULE_BUNDLE
    #define SWIFTPM_MODULE_BUNDLE [NSBundle bundleForClass:[self class]]
#endif

static NSString *const kSimpleNativeAdNibName = @"SimpleNativeAd";

/// The stacked layout's room at the text's end for the AdChoices icon (15pt, which the SDK puts
/// in the ad view's top-right corner): the headline doesn't run under it.
static const CGFloat kStackedAdChoicesRoom = 22.0;

@implementation SimpleNativeAdFactory

/// Returns the bundle that actually carries SimpleNativeAd.nib.
- (NSBundle *)nibBundle {
    NSBundle *moduleBundle = SWIFTPM_MODULE_BUNDLE;
    if ([moduleBundle URLForResource:kSimpleNativeAdNibName withExtension:@"nib"]) {
        return moduleBundle;
    }
    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    if ([classBundle URLForResource:kSimpleNativeAdNibName withExtension:@"nib"]) {
        return classBundle;
    }
    return [NSBundle mainBundle];
}

- (GADNativeAdView *)createNativeAd:(GADNativeAd *)nativeAd
                      customOptions:(NSDictionary *)customOptions {

    // To show the ad validator for debugging, set GADNativeAdValidatorEnabled to YES in Info.plist
    // NOTE: Outlet connections for NativeAdView don't work well, so you need to copy the XML directly
    // https://github.com/googleads/googleads-mobile-ios-examples/blob/f52b944ddf1f33a1014aff3bd8dd0f830c5391db/Swift/advanced/SwiftUIDemo/SwiftUIDemo/Native/NativeAdView.xib#L123

    // Create and place ad in view hierarchy: the row's layout from the .xib, the stacked one in code.
    BOOL stacked = [self isStacked:customOptions];
    GADNativeAdView *nativeAdView;
    if (stacked) {
        nativeAdView = [self stackedNativeAdView:customOptions];
    } else {
        NSBundle *bundle = [self nibBundle];
        nativeAdView = [bundle loadNibNamed:kSimpleNativeAdNibName
                                      owner:nil
                                    options:nil].firstObject;
    }

    // The ad sits in a fixed-size slot that the Flutter side lays out, so it cannot grow with
    // the user's text size. The labels use fixed fonts, but the call-to-action button is built
    // with UIButtonConfiguration, which follows Dynamic Type and ignores titleLabel.font. At the
    // largest accessibility sizes its title overflowed the slot and was drawn on top of other
    // Flutter screens. Cap the text size for the whole ad and clip anything that still overflows.
    if (@available(iOS 15.0, *)) {
        nativeAdView.maximumContentSizeCategory = UIContentSizeCategoryLarge;
    }
    nativeAdView.clipsToBounds = YES;

    // Get color mode from customOptions
    NSString *colorMode = customOptions[@"colorMode"] ?: @"auto";
    BOOL isDarkMode = [self isDarkMode:colorMode];

    // Apply color scheme based on color mode
    [self applyColorScheme:nativeAdView isDarkMode:isDarkMode];

    // Apply left padding if specified (the stacked layout takes it as it's built)
    NSNumber *leftPaddingValue = stacked ? nil : customOptions[@"leftPadding"];
    if (leftPaddingValue != nil) {
        CGFloat leftPadding = [leftPaddingValue doubleValue];
        [self applyLeftPadding:nativeAdView leftPadding:leftPadding];
    }

    // Apply right padding if specified (the stacked layout takes it as it's built)
    NSNumber *rightPaddingValue = stacked ? nil : customOptions[@"rightPadding"];
    if (rightPaddingValue != nil) {
        CGFloat rightPadding = [rightPaddingValue doubleValue];
        [self applyRightPadding:nativeAdView rightPadding:rightPadding];
    }

    // Associate the native ad view with the native ad object. This is
    // required to make the ad clickable.
    nativeAdView.nativeAd = nativeAd;

    ((UILabel *)nativeAdView.headlineView).text = nativeAd.headline;

    ((UILabel *)nativeAdView.bodyView).text = nativeAd.body;

    ((UIImageView *)nativeAdView.iconView).image = nativeAd.icon.image;

    UIImageView *iconImageView = (UIImageView *)nativeAdView.iconView;
    // The row's icon: its padding and corners (the stacked layout sets its own as it's built)
    if (!stacked) {
        // Adjust icon vertical padding based on screen size
        UIView *iconView = nativeAdView.iconView;
        CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
        CGFloat iconVerticalPadding = (screenWidth >= 600) ? 12.0 : 8.0; // Larger padding for iPad

        // Update icon view constraints for better spacing on larger screens
        // Only adjust top/bottom padding, not leading (left padding is controlled separately)
        for (NSLayoutConstraint *constraint in iconView.superview.constraints) {
            if (constraint.firstItem == iconView || constraint.secondItem == iconView) {
                if (constraint.firstAttribute == NSLayoutAttributeTop ||
                    constraint.firstAttribute == NSLayoutAttributeBottom) {
                    constraint.constant = iconVerticalPadding;
                }
            }
        }

        // Apply rounded corners to icon (dynamically calculated based on icon size)
        // NOTE: This overrides the static corner radius defined in SimpleNativeAd.xib (6pt)
        iconImageView.clipsToBounds = YES;
        // Use 6% of the icon width as corner radius for a subtle rounded effect
        // The static value in XIB is only used as a fallback for Interface Builder preview
        CGFloat iconWidth = iconImageView.frame.size.width;
        CGFloat cornerRadius = iconWidth * 0.06;
        iconImageView.layer.cornerRadius = cornerRadius;
    }

    // Add border to icon with dynamic color support for light/dark mode
    iconImageView.layer.borderWidth = 0.5;
    if (@available(iOS 13.0, *)) {
        // Use dynamic color for light/dark mode support
        iconImageView.layer.borderColor = [UIColor.tertiaryLabelColor CGColor];
    } else {
        // Fallback for iOS 12 and earlier
        iconImageView.layer.borderColor = [[UIColor colorWithWhite:0.0 alpha:0.12] CGColor];
    }

    [((UIButton *)nativeAdView.callToActionView) setTitle:nativeAd.callToAction
                                                  forState:UIControlStateNormal];

    // Adjust font size and styling for iPad vs iPhone
    // NOTE: This overrides the default button configuration font size from XIB
    // Size Class variations in XIB handle other text sizes (headline, body)
    UIButton *ctaButton = (UIButton *)nativeAdView.callToActionView;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        ctaButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    } else {
        ctaButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    }

    // Set CTA button styling to match iOS standard blue button style
    // White text on blue background for better visibility and conversion
    [ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    ctaButton.backgroundColor = UIColor.systemBlueColor;
    // Capsule shape (the stacked button isn't laid out yet: its height is known)
    ctaButton.layer.cornerRadius = (stacked ? [self stackedButtonHeight] : ctaButton.bounds.size.height) / 2.0;
    if (stacked) {
        if (@available(iOS 15.0, *)) {
            if (ctaButton.configuration != nil) {
                UIButtonConfiguration *configuration = ctaButton.configuration;
                configuration.title = nativeAd.callToAction;
                ctaButton.configuration = configuration;
            }
        }
    }

    // The app's label and colors, over the color mode's
    [self applyStyle:nativeAdView customOptions:customOptions];

    // In order for the SDK to process touch events properly, user interaction should be disabled.
    nativeAdView.callToActionView.userInteractionEnabled = NO;

    // Associate the native ad view with the native ad object. This is required to make the ad clickable.
    // Note: this should always be done after populating the ad views.
    nativeAdView.nativeAd = nativeAd;

    return nativeAdView;
}

- (BOOL)isStacked:(NSDictionary *)customOptions {
    return [customOptions[@"layout"] isEqual:@"stacked"];
}

- (BOOL)isPad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

/// The stacked layout's button: as high as the app's own buttons (40pt, iPad 48pt).
- (CGFloat)stackedButtonHeight {
    return [self isPad] ? 48.0 : 40.0;
}

/// The call-to-action's title font: 15pt (iPad 17pt), semibold on the stacked layout's wide button.
- (UIFont *)ctaFont:(NSDictionary *)customOptions {
    return [UIFont systemFontOfSize:([self isPad] ? 17.0 : 15.0)
                             weight:([self isStacked:customOptions] ? UIFontWeightSemibold : UIFontWeightRegular)];
}

/// The stacked layout, built in code: the icon and the text beside it (the headline, then the
/// "Ad" badge and the body in a row, as in the .xib, where adLabelIn: finds the badge), and the
/// call-to-action button on its own line under them, as wide as the ad. The icon is as high as
/// what's left over the button, so it grows with the slot. The text keeps clear of the AdChoices
/// icon in the top-right corner.
- (GADNativeAdView *)stackedNativeAdView:(NSDictionary *)customOptions {
    BOOL pad = [self isPad];
    CGFloat margin = pad ? 12.0 : 8.0;
    CGFloat gap = pad ? 12.0 : 10.0;
    NSNumber *leftPaddingValue = customOptions[@"leftPadding"];
    NSNumber *rightPaddingValue = customOptions[@"rightPadding"];
    CGFloat leading = leftPaddingValue != nil ? [leftPaddingValue doubleValue] : 12.0;
    CGFloat trailing = rightPaddingValue != nil ? [rightPaddingValue doubleValue] : 12.0;

    GADNativeAdView *nativeAdView = [[GADNativeAdView alloc] initWithFrame:CGRectMake(0, 0, 360, 122)];
    nativeAdView.backgroundColor = UIColor.clearColor;

    UIImageView *icon = [[UIImageView alloc] init];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.userInteractionEnabled = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.clipsToBounds = YES;
    icon.layer.cornerRadius = pad ? 12.0 : 10.0;

    UILabel *headline = [[UILabel alloc] init];
    headline.font = [UIFont boldSystemFontOfSize:(pad ? 17.0 : 15.0)];
    headline.numberOfLines = 2;
    headline.lineBreakMode = NSLineBreakByTruncatingTail;
    [headline setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1
                                              forAxis:UILayoutConstraintAxisVertical];

    UILabel *badge = [[UILabel alloc] init];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.text = @"Ad";
    badge.font = [UIFont systemFontOfSize:9.0];
    badge.textAlignment = NSTextAlignmentCenter;
    badge.layer.cornerRadius = 3.0;
    badge.layer.masksToBounds = YES;
    // A width of its own (applyStyle: widens it for a longer label)
    [badge.widthAnchor constraintEqualToConstant:23.0].active = YES;
    [badge.heightAnchor constraintEqualToConstant:15.0].active = YES;
    [badge setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [badge setContentCompressionResistancePriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisHorizontal];

    UILabel *body = [[UILabel alloc] init];
    body.font = [UIFont systemFontOfSize:(pad ? 14.0 : 12.0)];
    body.numberOfLines = 1;
    body.lineBreakMode = NSLineBreakByTruncatingTail;
    [body setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                          forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[badge, body]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8.0;

    UIStackView *texts = [[UIStackView alloc] initWithArrangedSubviews:@[headline, row]];
    texts.translatesAutoresizingMaskIntoConstraints = NO;
    texts.axis = UILayoutConstraintAxisVertical;
    texts.alignment = UIStackViewAlignmentFill;
    texts.spacing = 4.0;

    UIButton *cta;
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = [UIButtonConfiguration grayButtonConfiguration];
        configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        configuration.title = @"Install";
        configuration.titleLineBreakMode = NSLineBreakByTruncatingTail;
        UIFont *font = [self ctaFont:customOptions];
        configuration.titleTextAttributesTransformer =
            ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
                NSMutableDictionary<NSAttributedStringKey, id> *outgoing = [incoming mutableCopy];
                outgoing[NSFontAttributeName] = font;
                return outgoing;
            };
        cta = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    } else {
        cta = [UIButton buttonWithType:UIButtonTypeSystem];
        cta.titleLabel.font = [self ctaFont:customOptions];
    }
    cta.translatesAutoresizingMaskIntoConstraints = NO;

    [nativeAdView addSubview:icon];
    [nativeAdView addSubview:texts];
    [nativeAdView addSubview:cta];

    // The text beside the icon, centered on it while it fits, else kept between the top and the
    // button (a small icon).
    NSLayoutConstraint *centered = [texts.centerYAnchor constraintEqualToAnchor:icon.centerYAnchor];
    centered.priority = UILayoutPriorityDefaultHigh - 50;
    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:nativeAdView.leadingAnchor constant:leading],
        [icon.topAnchor constraintEqualToAnchor:nativeAdView.topAnchor constant:margin],
        [icon.bottomAnchor constraintEqualToAnchor:cta.topAnchor constant:-gap],
        [icon.widthAnchor constraintEqualToAnchor:icon.heightAnchor],
        [texts.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:gap],
        [texts.trailingAnchor constraintEqualToAnchor:nativeAdView.trailingAnchor
                                             constant:-MAX(trailing, kStackedAdChoicesRoom)],
        centered,
        [texts.topAnchor constraintGreaterThanOrEqualToAnchor:nativeAdView.topAnchor],
        [texts.bottomAnchor constraintLessThanOrEqualToAnchor:cta.topAnchor constant:-4.0],
        [cta.leadingAnchor constraintEqualToAnchor:nativeAdView.leadingAnchor constant:leading],
        [cta.trailingAnchor constraintEqualToAnchor:nativeAdView.trailingAnchor constant:-trailing],
        [cta.bottomAnchor constraintEqualToAnchor:nativeAdView.bottomAnchor constant:-margin],
        [cta.heightAnchor constraintEqualToConstant:[self stackedButtonHeight]],
    ]];

    nativeAdView.iconView = icon;
    nativeAdView.headlineView = headline;
    nativeAdView.bodyView = body;
    nativeAdView.callToActionView = cta;
    return nativeAdView;
}

- (BOOL)isDarkMode:(NSString *)colorMode {
    if ([colorMode isEqualToString:@"dark"]) {
        return YES;
    } else if ([colorMode isEqualToString:@"light"]) {
        return NO;
    } else {
        // Auto mode: check system theme
        if (@available(iOS 13.0, *)) {
            UIUserInterfaceStyle style = UIScreen.mainScreen.traitCollection.userInterfaceStyle;
            return style == UIUserInterfaceStyleDark;
        } else {
            return NO; // Default to light mode on iOS 12 and earlier
        }
    }
}

- (void)applyColorScheme:(GADNativeAdView *)nativeAdView isDarkMode:(BOOL)isDarkMode {
    // Get views
    UILabel *headlineLabel = (UILabel *)nativeAdView.headlineView;
    UILabel *bodyLabel = (UILabel *)nativeAdView.bodyView;
    UIImageView *iconView = (UIImageView *)nativeAdView.iconView;
    UIButton *ctaButton = (UIButton *)nativeAdView.callToActionView;

    UILabel *adLabel = [self adLabelIn:nativeAdView];

    if (isDarkMode) {
        // Dark mode colors
        nativeAdView.backgroundColor = [UIColor clearColor];
        headlineLabel.textColor = [UIColor whiteColor];
        bodyLabel.textColor = [UIColor colorWithRed:0x8E/255.0 green:0x8E/255.0 blue:0x93/255.0 alpha:1.0];
        iconView.backgroundColor = [UIColor colorWithRed:0x2C/255.0 green:0x2C/255.0 blue:0x2E/255.0 alpha:1.0];

        if (adLabel) {
            adLabel.backgroundColor = [UIColor colorWithRed:0x3A/255.0 green:0x3A/255.0 blue:0x3C/255.0 alpha:1.0];
            adLabel.textColor = [UIColor colorWithRed:0xEB/255.0 green:0xEB/255.0 blue:0xF5/255.0 alpha:1.0];
        }

        [ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        ctaButton.backgroundColor = [UIColor colorWithRed:0x0A/255.0 green:0x84/255.0 blue:0xFF/255.0 alpha:1.0];
    } else {
        // Light mode colors
        nativeAdView.backgroundColor = [UIColor clearColor];
        headlineLabel.textColor = [UIColor blackColor];
        bodyLabel.textColor = [UIColor colorWithRed:0x8E/255.0 green:0x8E/255.0 blue:0x93/255.0 alpha:1.0];
        iconView.backgroundColor = [UIColor colorWithRed:0xFC/255.0 green:0xFC/255.0 blue:0xFC/255.0 alpha:1.0];

        if (adLabel) {
            adLabel.backgroundColor = [UIColor colorWithRed:0xE5/255.0 green:0xE5/255.0 blue:0xEA/255.0 alpha:1.0];
            adLabel.textColor = [UIColor colorWithRed:0x3C/255.0 green:0x3C/255.0 blue:0x43/255.0 alpha:1.0];
        }

        [ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        ctaButton.backgroundColor = [UIColor colorWithRed:0x00/255.0 green:0x7A/255.0 blue:0xFF/255.0 alpha:1.0];
    }
}

/// The "Ad" attribution badge: the first label of the row under the headline.
- (UILabel *)adLabelIn:(GADNativeAdView *)nativeAdView {
    UIView *bodyView = nativeAdView.bodyView;
    if ([bodyView.superview isKindOfClass:[UIStackView class]]) {
        for (UIView *item in ((UIStackView *)bodyView.superview).arrangedSubviews) {
            if (item != bodyView && [item isKindOfClass:[UILabel class]]) {
                return (UILabel *)item;
            }
        }
    }
    return nil;
}

/// A color from Dart (0xAARRGGBB), or nil.
- (UIColor *)colorOption:(NSDictionary *)customOptions key:(NSString *)key {
    NSNumber *value = customOptions[key];
    if (![value isKindOfClass:[NSNumber class]]) return nil;
    uint32_t argb = (uint32_t)[value unsignedLongLongValue];
    return [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0
                           green:((argb >> 8) & 0xFF) / 255.0
                            blue:(argb & 0xFF) / 255.0
                           alpha:((argb >> 24) & 0xFF) / 255.0];
}

- (void)applyStyle:(GADNativeAdView *)nativeAdView customOptions:(NSDictionary *)customOptions {
    // The attribution badge's text, as wide as it needs (at least the "Ad" badge's 23pt)
    NSString *adLabelText = customOptions[@"adLabel"];
    UILabel *adLabel = [self adLabelIn:nativeAdView];
    if ([adLabelText isKindOfClass:[NSString class]] && adLabel != nil) {
        adLabel.text = adLabelText;
        CGFloat width = ceil([adLabelText sizeWithAttributes:@{NSFontAttributeName: adLabel.font}].width) + 8.0;
        for (NSLayoutConstraint *constraint in adLabel.constraints) {
            if (constraint.firstItem == adLabel && constraint.firstAttribute == NSLayoutAttributeWidth) {
                constraint.constant = MAX(23.0, width);
            }
        }
    }

    UIColor *primary = [self colorOption:customOptions key:@"primaryTextColor"];
    if (primary) ((UILabel *)nativeAdView.headlineView).textColor = primary;
    UIColor *secondary = [self colorOption:customOptions key:@"secondaryTextColor"];
    if (secondary) ((UILabel *)nativeAdView.bodyView).textColor = secondary;

    UIButton *ctaButton = (UIButton *)nativeAdView.callToActionView;
    UIColor *ctaBackground = [self colorOption:customOptions key:@"ctaBackgroundColor"];
    UIColor *ctaText = [self colorOption:customOptions key:@"ctaTextColor"];
    UIColor *ctaBorder = [self colorOption:customOptions key:@"ctaBorderColor"];
    if (ctaBackground) ctaButton.backgroundColor = ctaBackground;
    if (ctaText) [ctaButton setTitleColor:ctaText forState:UIControlStateNormal];
    // The button is built with UIButtonConfiguration (gray), whose own fill and title color
    // draw over the view's: set them there too.
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = ctaButton.configuration;
        if (configuration != nil && (ctaBackground || ctaText)) {
            if (ctaBackground) configuration.background.backgroundColor = ctaBackground;
            if (ctaText) configuration.baseForegroundColor = ctaText;
            // Keep the ad's call to action (the copy may still hold the layout's "Install")
            NSString *title = [ctaButton titleForState:UIControlStateNormal];
            if (title) configuration.title = title;
            // The configuration ignores titleLabel.font and draws 17pt: give it the 15pt
            // (iPad 17pt) set above, as Android's (semibold on the stacked layout's wide button).
            UIFont *font = [self ctaFont:customOptions];
            configuration.titleTextAttributesTransformer =
                ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
                    NSMutableDictionary<NSAttributedStringKey, id> *outgoing = [incoming mutableCopy];
                    outgoing[NSFontAttributeName] = font;
                    return outgoing;
                };
            ctaButton.configuration = configuration;
        }
    }
    if (ctaBorder) {
        ctaButton.layer.borderColor = ctaBorder.CGColor;
        ctaButton.layer.borderWidth = 0.5;
    }
}

- (void)applyLeftPadding:(GADNativeAdView *)nativeAdView leftPadding:(CGFloat)leftPadding {
    // Find the background view (first subview of nativeAdView)
    UIView *backgroundView = nativeAdView.subviews.firstObject;
    if (backgroundView == nil) return;

    // Update leading constraint of icon view
    for (NSLayoutConstraint *constraint in backgroundView.constraints) {
        // Find the leading constraint for the icon view
        if (constraint.firstAttribute == NSLayoutAttributeLeading &&
            constraint.firstItem == nativeAdView.iconView) {
            constraint.constant = leftPadding;
            break;
        }
    }
}

- (void)applyRightPadding:(GADNativeAdView *)nativeAdView rightPadding:(CGFloat)rightPadding {
    // Find the background view (first subview of nativeAdView)
    UIView *backgroundView = nativeAdView.subviews.firstObject;
    if (backgroundView == nil) return;

    // Update trailing constraint of CTA button
    for (NSLayoutConstraint *constraint in backgroundView.constraints) {
        // Find the trailing constraint for the CTA button
        if (constraint.firstAttribute == NSLayoutAttributeTrailing &&
            constraint.secondItem == nativeAdView.callToActionView) {
            constraint.constant = rightPadding;
            break;
        }
    }
}

@end
