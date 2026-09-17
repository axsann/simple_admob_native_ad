#import <Foundation/Foundation.h>
// Imported rather than forward declared so that Swift sees the protocol conformance:
// with only `@protocol FLTNativeAdFactory;` the importer drops it and the factory can no
// longer be passed to FLTGoogleMobileAdsPlugin.registerNativeAdFactory.
#import <google_mobile_ads/FLTGoogleMobileAdsPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleNativeAdFactory : NSObject<FLTNativeAdFactory>
@end

NS_ASSUME_NONNULL_END
