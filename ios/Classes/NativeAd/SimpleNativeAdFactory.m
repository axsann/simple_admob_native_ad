#import "SimpleNativeAdFactory.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <google_mobile_ads/FLTGoogleMobileAdsPlugin.h>

@implementation SimpleNativeAdFactory

- (GADNativeAdView *)createNativeAd:(GADNativeAd *)nativeAd
                      customOptions:(NSDictionary *)customOptions {

    // To show the ad validator for debugging, set GADNativeAdValidatorEnabled to YES in Info.plist
    // NOTE: Outlet connections for NativeAdView don't work well, so you need to copy the XML directly
    // https://github.com/googleads/googleads-mobile-ios-examples/blob/f52b944ddf1f33a1014aff3bd8dd0f830c5391db/Swift/advanced/SwiftUIDemo/SwiftUIDemo/Native/NativeAdView.xib#L123

    // Create and place ad in view hierarchy.
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    GADNativeAdView *nativeAdView = [bundle loadNibNamed:@"SimpleNativeAd"
                                                    owner:nil
                                                  options:nil].firstObject;

    // Get color mode from customOptions
    NSString *colorMode = customOptions[@"colorMode"] ?: @"auto";
    BOOL isDarkMode = [self isDarkMode:colorMode];

    // Apply color scheme based on color mode
    [self applyColorScheme:nativeAdView isDarkMode:isDarkMode];

    // Apply left padding if specified
    NSNumber *leftPaddingValue = customOptions[@"leftPadding"];
    if (leftPaddingValue != nil) {
        CGFloat leftPadding = [leftPaddingValue doubleValue];
        [self applyLeftPadding:nativeAdView leftPadding:leftPadding];
    }

    // Apply right padding if specified
    NSNumber *rightPaddingValue = customOptions[@"rightPadding"];
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
    UIImageView *iconImageView = (UIImageView *)nativeAdView.iconView;
    iconImageView.clipsToBounds = YES;
    // Use 6% of the icon width as corner radius for a subtle rounded effect
    // The static value in XIB is only used as a fallback for Interface Builder preview
    CGFloat iconWidth = iconImageView.frame.size.width;
    CGFloat cornerRadius = iconWidth * 0.06;
    iconImageView.layer.cornerRadius = cornerRadius;

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
    ctaButton.layer.cornerRadius = ctaButton.bounds.size.height / 2.0; // Capsule shape

    // In order for the SDK to process touch events properly, user interaction should be disabled.
    nativeAdView.callToActionView.userInteractionEnabled = NO;

    // Associate the native ad view with the native ad object. This is required to make the ad clickable.
    // Note: this should always be done after populating the ad views.
    nativeAdView.nativeAd = nativeAd;

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

    // Find Ad label (it's in a stack view)
    UILabel *adLabel = nil;
    for (UIView *subview in nativeAdView.subviews) {
        for (UIView *stackSubview in subview.subviews) {
            if ([stackSubview isKindOfClass:[UIStackView class]]) {
                UIStackView *stackView = (UIStackView *)stackSubview;
                for (UIView *stackItem in stackView.arrangedSubviews) {
                    if ([stackItem isKindOfClass:[UIStackView class]]) {
                        UIStackView *innerStack = (UIStackView *)stackItem;
                        for (UIView *innerItem in innerStack.arrangedSubviews) {
                            if ([innerItem isKindOfClass:[UILabel class]]) {
                                UILabel *label = (UILabel *)innerItem;
                                if ([label.text isEqualToString:@"Ad"]) {
                                    adLabel = label;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
