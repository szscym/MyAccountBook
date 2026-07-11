[app]
title = 我的账本
package.name = myaccountbook
package.domain = com.myaccountbook
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,ttf,ttc
source.include_patterns = *
version = 1.0.0
requirements = python3,kivy,kivymd
orientation = portrait
fullscreen = 0
icon = icon-512.png
android.api = 34
android.minapi = 21
android.sdk = 34
android.ndk = 27
android.build_tools = 34.0.0
android.enable_androidx = True
android.add_src = .

[buildozer]
log_level = 1
warn_on_root = 1