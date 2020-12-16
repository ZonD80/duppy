//
//  ViewController.swift
//  duppy2
//
//  Created by ZonD Eighty on 23.05.2020.
//  Copyright © 2020 appdb. All rights reserved.
//

import UIKit
import Swifter
import Zip
import Kingfisher

class ViewController: UIViewController , UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var othersAckButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBAction func tapOtherAckButton(_ sender: Any) {
        guard let url = URL(string: "https://github.com/ZonD80/duppy/graphs/contributors") else { return }
        UIApplication.shared.open(url)
    }
    func log(_ text:String) {
        print("[Duppy] "+text);
        NSLog(text);
    }
    
    func task(launchPath: String, arguments: String...) -> NSString {
        let task = NSTask.init()
        
        if (launchPath=="/bin/ls") {
        
        // do nothing
            
        } else {
            let programExists = self.task(launchPath: "/bin/ls", arguments: launchPath)
                
            if (programExists=="") {
                return ""; // there is no such program
            }
        }
        task?.setLaunchPath(launchPath)
        task?.arguments = arguments
        
        // Create a Pipe and make the task
        // put all the output there
        let pipe = Pipe()
        task?.standardOutput = pipe
        
        // Launch the task
        
        task?.launch()
        task?.waitUntilExit()
        
        // Get the data
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
        return output!
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyCollectionViewCell
                
        
        cell.appName.adjustsFontSizeToFitWidth = true
        cell.appName.minimumScaleFactor = 0.5
        cell.appStatus.adjustsFontSizeToFitWidth = true
        cell.appStatus.minimumScaleFactor = 0.5
        
        if (appModel[indexPath.row].isDRM!) {
            if (!FileManager.default.fileExists(atPath: "/var/mobile/Documents/CrackerXI/"+appModel[indexPath.row].mainBundleExecutable!)) {
                cell.appStatus.text = "⚠️\nDRM-protected."
            } else {
                cell.appStatus.text = "✅\nDRM-protected."
            }
        } else {
            cell.appStatus.text = "✅\nNot DRM-protected."
        }
        
        cell.appIcon.kf.setImage(with: URL(fileURLWithPath: appModel[indexPath.row].icon!), placeholder: UIImage(named: "icon.png"))
        cell.appName.text = appModel[indexPath.row].mainBundleName! as String
        
        if (appModel[indexPath.row].icon == "noicon") {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                cell.appIcon.kf.setImage(with: URL(fileURLWithPath:
                "/System/Library/PrivateFrameworks/MobileIcons.framework/DefaultIcon-60@2x~iphone.png"), placeholder: UIImage(named: "icon.png"))
            case .pad:
                cell.appIcon.kf.setImage(with: URL(fileURLWithPath:
                "/System/Library/PrivateFrameworks/MobileIcons.framework/DefaultIcon-76@2x~ipad.png"), placeholder: UIImage(named: "icon.png"))
            case .tv:
                cell.appIcon.image = nil
            case .carPlay:
                cell.appIcon.image = nil
            case .unspecified:
                cell.appIcon.image = nil
            @unknown default:
                cell.appIcon.image = nil
            }
        }
        else {
            cell.appIcon.kf.setImage(with: URL(fileURLWithPath: appModel[indexPath.row].icon!), placeholder: UIImage(named: "icon.png"))
        }
        
        cell.appIcon.layer.cornerRadius = 10
        cell.appIcon.clipsToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AppInfo" {
            guard let appInfoController = segue.destination as? AppInfoViewController else { return }
            guard let cell = sender as? UICollectionViewCell else { return }
            guard let indexPath = collectionView.indexPath(for: cell) else { return }
            
            let appObject = app(name: appModel[indexPath.row].name!, icon: appModel[indexPath.row].icon!, path: appModel[indexPath.row].path!, mainBundleId: appModel[indexPath.row].mainBundleId!, mainBundleName: appModel[indexPath.row].mainBundleName!, isDRM:appModel[indexPath.row].isDRM! ,mainBundleExecutable: appModel[indexPath.row].mainBundleExecutable!, mainBundleVersion: appModel[indexPath.row].mainBundleVersion!, trackId: appModel[indexPath.row].trackId!);
            
            appInfoController.appModel.append(appObject)
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 128, height: 128)
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var noOfCellsInRow = 0
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            noOfCellsInRow = 4
        case .pad:
            noOfCellsInRow = 6
        case .tv:
            noOfCellsInRow = 0
        case .carPlay:
            noOfCellsInRow = 0
        case .unspecified:
            noOfCellsInRow = 0
        @unknown default:
            noOfCellsInRow = 0
        }

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))

        return CGSize(width: size, height: 113)
    }
    
    func setStatusText(text: String) {
        DispatchQueue.main.async {
            self.statusText.text = text;
        }
    }
        
    @IBOutlet weak var statusText: UILabel!
    
    let selfAppPath = Bundle.main.bundlePath;
    let localPathURL = FileManager.default.temporaryDirectory;
    let appsPath = "/var/containers/Bundle/Application";
    var apps: [String: String] = [:];
    
    var appModel = [app]()
    
    override func viewDidLoad() {
        
        statusText.numberOfLines = 0;
        
        super.viewDidLoad()
        
        self.log("app path is \(self.selfAppPath)")
        self.log("documents path URL is \(self.localPathURL)");
        
        let perlTestResult = self.task(launchPath: "/usr/bin/perl",arguments: "-v");
            
            if (!perlTestResult.contains("This is perl")) {
                self.log("looks like there is no perl on device");
                self.setStatusText(text: "Looks there is no perl.\nPlease install perl from Cydia")
            } else {
        
        do {
            let appDirs = try FileManager.default.contentsOfDirectory(atPath: self.appsPath)
            
            //self.log("apps dirs are \(appDirs)")
            
            appDirs.forEach { appUUIDDir in
                do {
                    let appDirContents = try FileManager.default.contentsOfDirectory(atPath: "\(appsPath)/\(appUUIDDir)");
                    //print ("app dir contents are \(appDirContents)");
                    
                    appDirContents.forEach { appDir in
                        if appDir.hasSuffix(".app") {
                            let finalAppDir = "\(appsPath)/\(appUUIDDir)/\(appDir)";
                            //self.log("found final app dir \(finalAppDir)");
                            apps[appDir] = finalAppDir;
                            
                            let mainInfoPlistURL = URL(fileURLWithPath: "\(finalAppDir)/Info.plist");
                            

                            
                            let iTunesMetadataPlistURL = URL(fileURLWithPath: "\(appsPath)/\(appUUIDDir)/iTunesMetadata.plist");
                            
                            var iTunesMetadataPlistEntities:NSDictionary = [:];
                            
                            var trackId:String = "";
                            
                            do {
                                iTunesMetadataPlistEntities = try PropertyListSerialization.propertyList(from: Data(contentsOf: iTunesMetadataPlistURL), options: [], format: nil) as! NSDictionary
                                trackId = String(describing: iTunesMetadataPlistEntities["itemId"] ?? "") // wtf. it is stupid af
                            } catch {
                                self.log("App is not from appstore. okay");
                            }
                            
                            
                            var mainBundleId:String = appDir;
                            var mainBundleName:String = appDir;
                            
                            var mainBundleExecutable:String = "";
                            var mainBundleIcon:String = ""
                            var mainBundleVersion:String = ""
                            
                            do {
                                let mainInfoPlistEntities = try PropertyListSerialization.propertyList(from: Data(contentsOf: mainInfoPlistURL), options: [], format: nil) as! NSDictionary
                                
                                self.log("display name is :\(mainInfoPlistEntities["CFBundleDisplayName"])");
                                
                                mainBundleId = mainInfoPlistEntities["CFBundleIdentifier"] as! String
                                if (mainBundleId.hasPrefix("com.apple.")) {
                                    // it's apple software
                                    return;
                                }
                                if mainInfoPlistEntities["CFBundleDisplayName"] != nil {
                                    mainBundleName = mainInfoPlistEntities["CFBundleDisplayName"] as! String
                                }
                                else {
                                    mainBundleName = mainInfoPlistEntities["CFBundleName"] as! String
                                }
                                if mainInfoPlistEntities["CFBundleExecutable"] != nil {
                                    mainBundleExecutable = mainInfoPlistEntities["CFBundleExecutable"] as! String
                                }
                                if mainInfoPlistEntities["CFBundleIcons"] != nil {
                                    let findIcons = mainInfoPlistEntities["CFBundleIcons"] as! NSDictionary
                                    let primaryIcons = findIcons["CFBundlePrimaryIcon"] as! NSDictionary
                                    let locateIconName = primaryIcons["CFBundleIconFiles"] as! NSArray
                                    mainBundleIcon = "\(finalAppDir)/\(locateIconName.lastObject as! String)@2x.png"
                                }
                                else {
                                    mainBundleIcon = "noicon"
                                }
                                if mainInfoPlistEntities["CFBundleShortVersionString"] != nil {
                                    mainBundleVersion = mainInfoPlistEntities["CFBundleShortVersionString"] as! String
                                }
                            } catch {
                                self.log("Unable to get app name")
                            }
                            
                            var isDRM = false;
                            if (FileManager.default.fileExists(atPath: "\(finalAppDir)/SC_Info/Manifest.plist")) {
                                isDRM = true;
                            }
                            let appObject = app(name: appDir, icon: mainBundleIcon, path: finalAppDir, mainBundleId: mainBundleId, mainBundleName: mainBundleName, isDRM:isDRM,mainBundleExecutable: mainBundleExecutable, mainBundleVersion: mainBundleVersion, trackId: trackId);
                            appModel.append(appObject);
                            return;
                        }
                    }
                    statusText.text = "Apps loaded\nTap on app to clone it";
                    
                }
                catch {
                    self.log("unable to get contents of app dir \(error)");
                }
            }
            
            let localPath = localPathURL.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            self.log("local path is \(localPath)");
            
            DispatchQueue.global(qos: .background).async {
                let server = HttpServer()
                server["/"] = { request in
                    return HttpResponse.ok(.text("OK"))
                }
                server["/download/:path"]  = shareFilesFromDirectory(localPath);
                //server["/test"] =
                do {
                    try server.start(44443, forceIPv4: true)
                    self.log("Server has started ( port = \(try server.port()) ). Try to connect now...")
                    self.log("\(server.state)");
                    //semaphore.wait()
                } catch {
                    self.log("Server start error: \(error)")
                    //semaphore.signal()
                }
            }
            
            
        } catch {
            self.log("unable to get app dirs \(error)");
            self.setStatusText(text: "Looks like your device is not jailbroken")
        }
            }
        
        
        view.backgroundColor = .backgroundColor
        collectionView.backgroundColor = .backgroundColor
        
        let layout = UICollectionViewFlowLayout()
        collectionView.collectionViewLayout = layout
        layout.itemSize = CGSize(width: 128, height: 128)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        longPressGR.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(longPressGR)
    }
    
    
    @objc
    func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if longPressGR.state != .ended {
            return
        }

        let point = longPressGR.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)

        if let indexPath = indexPath {
            var cell = self.collectionView.cellForItem(at: indexPath)
            print(indexPath.row)
        } else {
            print("Could not find index path")
        }
    }
    
}
