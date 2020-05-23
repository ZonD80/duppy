<p align="center">
  <img src="https://user-images.githubusercontent.com/273057/82735535-1f269c00-9d2b-11ea-827d-5ee252f21ba9.png" alt="duppy icon" title="duppy" height="130"/>
</p>

#  Duppy

<p align="center">
  <img src="https://img.shields.io/badge/PRs-welcome-green"/>
  <img src="https://img.shields.io/github/license/ZonD80/duppy"/>
  <img src="https://img.shields.io/github/issues/ZonD80/duppy"/>
</p>

This app is designed to "clone" iOS apps on **jailbroken** devices with [AppSync](https://cydia.akemi.ai/?page/net.angelxwind.appsyncunified) installed.
It works like this:

1. Copying original app contents.
2. Replacing occurences of bundle ID in all Info.plist files to new ones.
3. Packing app to IPA archive.
4. Requesting install of app via itms-services protocol.

That's it!

## Dependencies
* [swifter](https://github.com/httpswift/swifter) - Tiny http server engine written in Swift programming language
* [Zip](https://github.com/marmelroy/Zip) - Swift framework for zipping and unzipping files

## Download
You can download the latest .ipa from [here](https://github.com/ZonD80/duppy/releases).

## Build manually
Alernatively, you can build the project manually. 
Make sure you have [Carthage](https://github.com/Carthage/Carthage) installed. Run the following commands:
```
$ git clone https://github.com/ZonD80/duppy.git
$ cd duppy2/
$ carthage update --platform iOS
$ open duppy2.xcodeproj
```

## License
GNU General Public License v3.0. See [LICENSE](LICENSE) file for further information.

## To improve
I personally feel fine with existing features, but this is what you can improve by making a PR:

* Add app icons to table
* Make webserver that is used for itms-services run when app is minimised
* Make interface more fancy
* Allow to update duplicated app by matching it bundle ID with "duppy" and copying from original app over duplicated app
* Make free space checks (at least 2x space of size original uncompressed app foulder should be available)
