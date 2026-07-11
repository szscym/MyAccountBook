[app]
title = 我的账本
package.name = myaccountbook
package.domain = com.myaccountbook
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,ttf,ttc
source.include_patterns = *
version = 1.0.0
requirements = python3,kivy==2.3.1,kivymd==1.2.0
orientation = portrait
fullscreen = 0
icon = icon-512.png
presplash_color = #2E7D32
android.api = 34
android.minapi = 21
android.sdk = 34
android.ndk = 27
android.enable_androidx = True

[buildozer]
log_level = 1
warn_on_root = 1
