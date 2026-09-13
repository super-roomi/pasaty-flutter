# Flutter wraps its own engine rules; these cover the plugins this app ships.

# socket_io_client / http operate purely in Dart — no native keep rules needed.

# geolocator and flutter_map reference Play Services location classes
# reflectively on some devices.
-keep class com.google.android.gms.location.** { *; }

# Keep annotations used by AndroidX/Play Services.
-keepattributes *Annotation*
-keepattributes Signature
