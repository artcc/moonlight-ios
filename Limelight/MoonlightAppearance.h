#import <UIKit/UIKit.h>

// Shared visual styling for browsing and transient connection UI.
static inline UIColor* MLBackgroundColor(void) {
    return [UIColor colorWithRed:0.05 green:0.07 blue:0.11 alpha:1.0];
}

static inline UIColor* MLSurfaceColor(void) {
    return [UIColor colorWithRed:0.10 green:0.13 blue:0.19 alpha:1.0];
}

static inline UIColor* MLAccentColor(void) {
    return [UIColor colorWithRed:0.40 green:0.76 blue:0.94 alpha:1.0];
}

static inline UIColor* MLTextColor(void) {
    return [UIColor colorWithRed:0.95 green:0.97 blue:1.0 alpha:1.0];
}

static inline UIColor* MLSecondaryTextColor(void) {
    return [UIColor colorWithRed:0.65 green:0.71 blue:0.81 alpha:1.0];
}

static inline UIColor* MLBorderColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.12];
}

static inline UIColor* MLPairingColor(void) {
    return [UIColor colorWithRed:1.0 green:0.73 blue:0.36 alpha:1.0];
}

static inline UIColor* MLOfflineColor(void) {
    return [UIColor colorWithRed:0.98 green:0.50 blue:0.56 alpha:1.0];
}

// Bake the surface into the image so tvOS can apply its native image focus effect.
static inline UIImage* MLCardImage(CGSize size, CGFloat cornerRadius, UIImage* symbol) API_AVAILABLE(ios(10.0), tvos(10.0)) {
    UIGraphicsImageRenderer* renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext* context) {
        CGRect bounds = CGRectMake(0, 0, size.width, size.height);
        UIBezierPath* outline = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(bounds, 0.5, 0.5)
                                                         cornerRadius:cornerRadius];
        [MLSurfaceColor() setFill];
        [outline fill];
        [MLBorderColor() setStroke];
        outline.lineWidth = 1.0;
        [outline stroke];

        if (symbol != nil) {
            CGRect symbolFrame = CGRectMake((size.width - symbol.size.width) / 2,
                                            (size.height - symbol.size.height) / 2,
                                            symbol.size.width, symbol.size.height);
            [symbol drawInRect:symbolFrame];
        }
    }];
}

// Preserve the existing overlay frames and provide legacy assets when symbols are unavailable.
static inline UIImage* MLBadgeImage(NSString* symbolName, UIColor* color, NSString* fallbackAssetName) {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        UIImageSymbolConfiguration* configuration = [UIImageSymbolConfiguration configurationWithPointSize:26.0
                                                                                                    weight:UIImageSymbolWeightSemibold];
        UIImage* symbol = [UIImage systemImageNamed:symbolName withConfiguration:configuration];
        if (symbol != nil) {
            symbol = [symbol imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
            UIGraphicsImageRenderer* renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(64, 64)];
            return [renderer imageWithActions:^(UIGraphicsImageRendererContext* context) {
                UIBezierPath* background = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, 60, 60)];
                [[MLBackgroundColor() colorWithAlphaComponent:0.95] setFill];
                [background fill];
                [[color colorWithAlphaComponent:0.65] setStroke];
                background.lineWidth = 2.0;
                [background stroke];
                [symbol drawInRect:CGRectMake((64 - symbol.size.width) / 2,
                                             (64 - symbol.size.height) / 2,
                                             symbol.size.width, symbol.size.height)];
            }];
        }
    }
    return [UIImage imageNamed:fallbackAssetName];
}
