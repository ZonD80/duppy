<p align="center">
  <img src="https://user-images.githubusercontent.com/273057/82735535-1f269c00-9d2b-11ea-827d-5ee252f21ba9.png" alt="duppy icon" title="duppy" height=130>
</p>

#  Duppy

[https://img.shields.io/badge/PRs-welcome-green] [https://img.shields.io/github/license/ZonD80/duppy] [https://img.shields.io/github/issues/ZonD80/duppy]

This app is designed to "clone" iOS apps.
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
