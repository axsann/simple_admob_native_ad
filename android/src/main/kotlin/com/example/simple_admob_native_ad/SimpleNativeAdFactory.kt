package com.example.simple_admob_native_ad

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class SimpleNativeAdFactory: NativeAdFactory {
    private var layoutInflater: LayoutInflater
    private var context: Context

    constructor(layoutInflater: LayoutInflater, context: Context) {
        this.layoutInflater = layoutInflater
        this.context = context
    }

    override fun createNativeAd(nativeAd: NativeAd?, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.simple_native_ad, null) as NativeAdView

        // Set other ad assets.
        adView.headlineView = adView.findViewById(R.id.primary)
        adView.bodyView = adView.findViewById(R.id.secondary)
        adView.callToActionView = adView.findViewById(R.id.cta)
        adView.iconView = adView.findViewById(R.id.icon)

        (adView.headlineView as TextView).text = nativeAd?.headline

        // These assets aren't guaranteed to be in every NativeAd, so it's important to
        // check before trying to display them.
        if (nativeAd?.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd?.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd?.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon!!.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }
        // For API level 21 (Android 5.0 Lollipop) and above, apply rounded corners dynamically based on icon size.
        // NOTE: This overrides the static corner radius defined in res/drawable/ad_banner_icon_background.xml
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            adView.iconView?.post {
                val iconView = adView.iconView
                if (iconView != null) {
                    // Use 10% of the icon width as corner radius for a more visible rounded effect
                    // The static value in XML (6dp) is only used as a fallback for older devices
                    val cornerRadius = iconView.width * 0.10f
                    val background = iconView.background as? android.graphics.drawable.GradientDrawable
                    background?.cornerRadius = cornerRadius

                    // Also set outline provider to ensure proper clipping
                    iconView.outlineProvider = object : android.view.ViewOutlineProvider() {
                        override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                            outline.setRoundRect(0, 0, view.width, view.height, cornerRadius)
                        }
                    }
                    iconView.clipToOutline = true
                }
            }
        }

        // This method tells the Google Mobile Ads SDK that you have finished populating your
        // native ad view with this native ad.
        if (nativeAd != null) {
            adView.setNativeAd(nativeAd)
        }

        // Get color mode from customOptions and apply colors AFTER all other setup
        // This ensures color settings aren't overwritten by other operations
        val colorMode = customOptions?.get("colorMode") as? String ?: "auto"
        applyColorMode(adView, colorMode)

        // Apply left padding if specified
        val leftPadding = customOptions?.get("leftPadding") as? Double
        if (leftPadding != null) {
            applyLeftPadding(adView, leftPadding)
        }

        // Apply right padding if specified
        val rightPadding = customOptions?.get("rightPadding") as? Double
        if (rightPadding != null) {
            applyRightPadding(adView, rightPadding)
        }

        return adView
    }

    private fun applyLeftPadding(adView: NativeAdView, leftPadding: Double) {
        val background = adView.findViewById<View>(R.id.background)
        val layoutParams = background.layoutParams as? androidx.constraintlayout.widget.ConstraintLayout.LayoutParams
        if (layoutParams != null) {
            // Convert dp to pixels
            val density = context.resources.displayMetrics.density
            layoutParams.marginStart = (leftPadding * density).toInt()
            background.layoutParams = layoutParams
        }
    }

    private fun applyRightPadding(adView: NativeAdView, rightPadding: Double) {
        val background = adView.findViewById<View>(R.id.background)
        val layoutParams = background.layoutParams as? androidx.constraintlayout.widget.ConstraintLayout.LayoutParams
        if (layoutParams != null) {
            // Convert dp to pixels
            val density = context.resources.displayMetrics.density
            layoutParams.marginEnd = (rightPadding * density).toInt()
            background.layoutParams = layoutParams
        }
    }

    private fun applyColorMode(adView: NativeAdView, colorMode: String) {
        val isDarkMode = when (colorMode) {
            "dark" -> true
            "light" -> false
            else -> {
                // Auto mode: check system theme
                val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                nightModeFlags == Configuration.UI_MODE_NIGHT_YES
            }
        }

        // Apply colors based on dark mode
        val background = adView.findViewById<View>(R.id.background)
        val primaryText = adView.findViewById<TextView>(R.id.primary)
        val secondaryText = adView.findViewById<TextView>(R.id.secondary)
        val adLabel = adView.findViewById<TextView>(R.id.ad_notification_view)
        val ctaButton = adView.findViewById<Button>(R.id.cta)
        val icon = adView.findViewById<ImageView>(R.id.icon)

        if (isDarkMode) {
            // Dark mode colors

            // Text colors
            primaryText?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_default_text_dark))
            secondaryText?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_gray_text_dark))

            // Ad label
            adLabel?.setBackgroundResource(0)
            adLabel?.setBackgroundColor(ContextCompat.getColor(context, R.color.ad_banner_ad_label_background_dark))
            adLabel?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_ad_label_text_dark))

            // Icon - create drawable with dark background
            val iconDrawable = android.graphics.drawable.GradientDrawable()
            iconDrawable.setColor(ContextCompat.getColor(context, R.color.ad_banner_icon_background_dark))
            iconDrawable.cornerRadius = icon?.width?.toFloat()?.times(0.10f) ?: 8f
            icon?.background = iconDrawable

            // CTA button
            ctaButton?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_cta_text_dark))
            val ctaDrawable = android.graphics.drawable.GradientDrawable()
            ctaDrawable.setColor(ContextCompat.getColor(context, R.color.ad_banner_cta_button_background_dark))
            ctaDrawable.cornerRadius = 100f  // Large radius for capsule shape
            ctaButton?.background = ctaDrawable

        } else {
            // Light mode colors

            // Text colors
            primaryText?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_default_text_light))
            secondaryText?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_gray_text_light))

            // Ad label
            adLabel?.setBackgroundResource(0)
            adLabel?.setBackgroundColor(ContextCompat.getColor(context, R.color.ad_banner_ad_label_background_light))
            adLabel?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_ad_label_text_light))

            // Icon - create drawable with light background
            val iconDrawable = android.graphics.drawable.GradientDrawable()
            iconDrawable.setColor(ContextCompat.getColor(context, R.color.ad_banner_icon_background_light))
            iconDrawable.cornerRadius = icon?.width?.toFloat()?.times(0.10f) ?: 8f
            icon?.background = iconDrawable

            // CTA button
            ctaButton?.setTextColor(ContextCompat.getColor(context, R.color.ad_banner_cta_text_light))
            val ctaDrawable = android.graphics.drawable.GradientDrawable()
            ctaDrawable.setColor(ContextCompat.getColor(context, R.color.ad_banner_cta_button_background_light))
            ctaDrawable.cornerRadius = 100f  // Large radius for capsule shape
            ctaButton?.background = ctaDrawable
        }
    }
}
