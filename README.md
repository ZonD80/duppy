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

## Build and install manually


Alernatively, you can build the project manually. 
Make sure you have [Carthage](https://github.com/Carthage/Carthage) ,**ldid**, [ideviceisntaller](https://github.com/libimobiledevice/ideviceinstaller) are installed, you can install them via [Homebrew](https://github.com/Homebrew)
Run the following commands:
```
$ git clone https://github.com/ZonD80/duppy.git
$ cd duppy2/
$ carthage update --platform iOS
$ open duppy2.xcodeproj
```

Do not install app to device via xCode, as it is still missing required entilements. To add them:
1. Archive your product (Command-Shift-B) then Control-Click on latest archive and select "Show in Finder"
2. Control-Clck on *.xcarchive and select "Show Package Contents"
3. Navigate to Products->Applications folder->Duppy.app folder
4. Open Termonal and type string ends with space)
```
$ ldid -SEntitlements.xml 
```
Drop Duppy file to Terminal and press Enter

6. To verify that Entitlements were set, type (string ends with space):
```
$ codesign -dvvv --entitlements - 
```
and drop Duppy file to Terminal.

7. Go to upper "Applications" folder. Type in Terminal  (string ends with space):
```
$ ideviceinstaller -i 
```

And drop Duppy.app folder to Terminal - app should be installed to device.

## License
GNU General Public License v3.0. See [LICENSE](LICENSE) file for further information.

## To improve
I personally feel fine with existing features, but this is what you can improve by making a PR:

* Add app icons to table
* Make webserver that is used for itms-services run when app is minimised
* Make interface more fancy
* Allow to update duplicated app by matching it bundle ID with "duppy" and copying from original app over duplicated app
* Make free space checks (at least 2x space of size original uncompressed app folder should be available)
