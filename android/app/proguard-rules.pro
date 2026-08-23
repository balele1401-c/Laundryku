# Flutter ProGuard / R8 Optimization Rules

# Keep Flutter engine & framework entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase Core & Firestore & Auth
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.plugins.firebase.**

# Keep SVG / Vector graphics
-dontwarn com.caverock.androidsvg.**

# Suppress Play Store deferred components & harmless warnings
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn kotlin.**
