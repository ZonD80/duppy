<p align="center">
  <img src="https://user-images.githubusercontent.com/273057/82735535-1f269c00-9d2b-11ea-827d-5ee252f21ba9.png" alt="duppy icon" title="duppy" height="130"/>
</p>

#  Duppy

<p align="center">
  <img src="https://img.shields.io/badge/PRs-welcome-green"/>
  <img src="https://img.shields.io/github/license/ZonD80/duppy"/>
  <img src="https://img.shields.io/github/issues/ZonD80/duppy"/>
</p>

This app is designed to "clone" iOS apps on **jailbroken** devices with [AppSync](https://github.com/akemin-dayo/AppSync) installed. Compatible with iOS 12+
It works like this:

1. Copying original app contents.
2. Replacing occurences of bundle ID in all Info.plist files to new ones.
3. Packing app to IPA archive.
4. Requesting install of app via itms-services protocol.

That's it!

## Dependencies
* [swifter](https://github.com/httpswift/swifter) - Tiny http server engine written in Swift programming language
* [Zip](https://github.com/marmelroy/Zip) - Swift framework for zipping and unzipping files
* [Kingfisher](https://github.com/onevcat/Kingfisher) - A lightweight, pure-Swift library for downloading and caching images from the web. 
* [ldid](https://github.com/ProcursusTeam/ldid) - fork of Saurik's ldid by ProcursusTeam

## Install
You can download the latest .ipa from [Duppy.bfsc.to](https://duppy.bfsc.to) website by tapping on install link. **Do not use another installers, as they may break IPA**.

## Download
You can download the latest .ipa from [here](https://github.com/ZonD80/duppy/releases).

## Build and install manually


Alernatively, you can build the project manually. 
Make sure you have [Carthage](https://github.com/Carthage/Carthage) and [appdb build tools](https://github.com/appdb-official/appdb-build-tools)
Run the following commands:
```
$ git clone https://github.com/ZonD80/duppy.git
$ cd duppy/
$ carthage update --platform iOS --use-xcframeworks
$ open duppy2.xcodeproj
```

Build this app with ```embed.entitlements``` during signature phase.

## License
GNU General Public License v3.0. See [LICENSE](LICENSE) file for further information.

## To improve
I personally feel fine with existing features, but this is what you can improve by making a PR:

* Find a way to integrate [frida-ios-dump](https://github.com/AloneMonkey/frida-ios-dump) or any other binary dumper
* Make webserver that is used for itms-services run when app is minimised
* Allow to update duplicated app by specifying alongside bundle ID manually
* Make free space checks (at least 2x space of size original uncompressed app folder should be available (copy of App folder, App archive))
