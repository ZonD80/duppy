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

class ViewController: UIViewController , UITableViewDataSource , UITableViewDelegate {
    
    @IBOutlet weak var othersAckButton: UIButton!
    
    @IBAction func tapOtherAckButton(_ sender: Any) {
        guard let url = URL(string: "https://github.com/ZonD80/duppy/graphs/contributors") else { return }
        UIApplication.shared.open(url)
    }
    func log(_ text:String) {
        //print(text);
        NSLog(text);
    }
    
    
    func task(launchPath: String, arguments: String...) -> NSString {
        let task = NSTask.init()
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
    
    let localPathURL = FileManager.default.temporaryDirectory;
    var isAppCloningNow: Bool = false;
    let selfAppPath = Bundle.main.bundlePath;
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appModel.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .value2, reuseIdentifier: "reuseIdentifier")
        }
        let text1:String!
        let text2:String!
        
        if (appModel[indexPath.row].isDRM!) {
            if (!FileManager.default.fileExists(atPath: "/var/mobile/Documents/CrackerXI/"+appModel[indexPath.row].mainBundleExecutable!)) {
                text1 = "⚠️ \(appModel[indexPath.row].mainBundleName! as String)"
                text2 = "DRM-protected."
            } else {
                text1 = "✅ \(appModel[indexPath.row].mainBundleName! as String)"
                text2 = "DRM-protected."
            }
        } else {
            text1 = "✅ \(appModel[indexPath.row].mainBundleName! as String)"
            text2 = "Not DRM-protected."
        }
        
        cell?.textLabel?.text = text1
        cell?.detailTextLabel?.text = text2
        if (appModel[indexPath.row].icon == "noicon") {
            cell?.imageView?.kf.setImage(with: URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MobileIcons.framework/DefaultIcon-60@2x~iphone.png"), placeholder: UIImage(named: "icon.png"))
        }
        else {
            cell?.imageView?.kf.setImage(with: URL(fileURLWithPath: appModel[indexPath.row].icon!), placeholder: UIImage(named: "icon.png"))
        }
        cell?.imageView?.layer.cornerRadius = 10
        cell?.imageView?.clipsToBounds = true
        return cell!
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let fm = FileManager.default
        let size = fm.directorySize(URL(fileURLWithPath: appModel[indexPath.row].path!))
        var refreshAlert: UIAlertController;
        refreshAlert = UIAlertController(title: "\(appModel[indexPath.row].mainBundleName! as String)", message: "Version: \(appModel[indexPath.row].mainBundleVersion! as String)\nSize: \(humanReadableByteCount(bytes: size!))\nID: \(appModel[indexPath.row].mainBundleId! as String)", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func humanReadableByteCount(bytes: Int) -> String {
        if (bytes < 1000) { return "\(bytes) B" }
        let exp = Int(log2(Double(bytes)) / log2(1000.0))
        let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
        let number = Double(bytes) / pow(1000, Double(exp))
        return String(format: "%.1f %@", number, unit)
    }
    
    func setStatusText(text: String) {
        DispatchQueue.main.async {
            self.statusText.text = text;
        }
    }
    
    func cloneApp(app: app, separateBinary:Bool = false) {
        
        self.isAppCloningNow = true;
        
        self.setStatusText(text: "Starting to clone");
        
        let localPath = localPathURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        let archiverQueue = DispatchQueue(label: "archiver")
        archiverQueue.async {
            
            let appName = app.name! as String;
            let appPath = app.path! as String;
            self.log("cloning \(appName) at path \(appPath)")
            self.log("clearing temp dir: "+localPath+"/work_dir/Payload")
            
            do {
                try FileManager.default.removeItem(atPath: localPath+"/work_dir/Payload")
            } catch {
                self.log("unable to remove temp dir \(error) we can give up on it");
                //self.isAppCloningNow = false;
                //self.setStatusText(text: "ERROR: unable to remove temp dir")
                //return;
            }
            do {
                try FileManager.default.createDirectory(atPath: localPath+"/work_dir/Payload", withIntermediateDirectories: true, attributes: nil)
            } catch {
                self.log("unable to create temp dir \(error)");
                self.isAppCloningNow = false;
                self.setStatusText(text: "ERROR: unable to create temp dir \(localPath)/work_dir/Payload")
                return;
            
            }
            
            self.log("Copying app data")
            
            self.setStatusText(text: "Copying original app data");
            
            do { try FileManager.default.copyItem(at: URL(string: "file://"+appPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!, to: URL(string: "file://"+localPath+"/work_dir/Payload/\(appName)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!)
            }
            catch {
                self.log("unable to copy dir \(error)");
                self.setStatusText(text: "ERROR: unable to copy original app data")
                self.isAppCloningNow = false;
                return;
            }
            
            if separateBinary {
                do {
                    self.log("using separate binary!");
                    let destinationBinaryURL = URL(string: "file://"+localPath+"/work_dir/Payload/\(appName)/"+app.mainBundleExecutable!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!);
                    try FileManager.default.removeItem(at: destinationBinaryURL!);
                    try FileManager.default.copyItem(at: URL(string: "file:///var/mobile/Documents/CrackerXI/"+app.mainBundleExecutable!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!, to: destinationBinaryURL!)
                }
                catch {
                    self.log("unable to copy separate binary \(error)");
                    self.setStatusText(text: "ERROR: unable to copy separate binary")
                    self.isAppCloningNow = false;
                    return;
                }
            }
            
            self.log("App data copied")
            
            do { // removing SC_info, as it is not under FairPlay
                try FileManager.default.removeItem(at: URL(string: "file://"+localPath+"/work_dir/Payload/\(appName)/SC_Info")!);
            }
            catch {
                self.log("unable to remove SC_Info dir \(error), but we can give up");
            }
            
            self.setStatusText(text: "Making some magic");
            
            self.log("Searching for PLISTS and converting them to XML formats")
            
            let url = URL(fileURLWithPath: localPath+"/work_dir/Payload")
            
            let mainInfoPlistURL = URL(fileURLWithPath: localPath+"/work_dir/Payload/\(appName)/Info.plist");
            
            var newBundleId:String="";
            
            do {
                let mainInfoPlistEntitiesDict = try PropertyListSerialization.propertyList(from: Data(contentsOf: mainInfoPlistURL), options: [], format: nil) as! NSDictionary
                let mainInfoPlistEntities:NSMutableDictionary = mainInfoPlistEntitiesDict.mutableCopy() as! NSMutableDictionary
                
                let mainBundleId = mainInfoPlistEntities["CFBundleIdentifier"] as! String
                self.log("Main bundle id is \(mainBundleId)")
                
                newBundleId = "duppy."+self.randomString(length: 5)+"."+mainBundleId;
                
                self.log("Replacement bundle id is \(newBundleId)")
                
                mainInfoPlistEntities["CFBundleDisplayName"] = app.mainBundleName;
                
                do { try mainInfoPlistEntities.write(to: mainInfoPlistURL);
                    
                }
                catch {
                    self.log("unable to write to info plist")
                    self.setStatusText(text: "Unable to write to Info.plist")
                    return;
                }
                
                
                var files = [URL]()
                var plistEntities: [String:NSDictionary] = [:];
                
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [], options: []) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                            if fileAttributes.isRegularFile! {
                                if fileURL.absoluteString.hasSuffix("Info.plist") {
                                    let plistData = try Data(contentsOf: fileURL);
                                    
                                    do {
                                        plistEntities[fileURL.absoluteString] = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? NSDictionary
                                        
                                        //print (InfoPlistEntities);
                                        var executableName:String = "";
                                        if plistEntities[fileURL.absoluteString]!["CFBundleExecutable"] != nil {
                                            executableName = plistEntities[fileURL.absoluteString]!["CFBundleExecutable"] as! String
                                            self.log("found executable \(executableName) in plist at location \(fileURL.absoluteString), changing entitlements")
                                            let executablePath = fileURL.absoluteString.replacingOccurrences(of: "Info.plist", with: executableName).replacingOccurrences(of: "file://", with: "")
                                            //print ("command: /usr/bin/ldid -e '\(executablePath)'")
                                            let existingEntitlements = self.task(launchPath: "/usr/bin/ldid",arguments: "-e",executablePath);
                                            self.log("existing entitlements are: \(existingEntitlements)");
                                            
                                            if (existingEntitlements.contains(mainBundleId)) {
                                                var fixedEntitlements = existingEntitlements.replacingOccurrences(of: mainBundleId, with: newBundleId)
                                                self.log("FIXED entitlements are: \(fixedEntitlements)");
                                                try fixedEntitlements.write(toFile: localPath+"/work_dir/Entitlements.xml", atomically: true, encoding: .utf8)
                                                let entitlementWriteResult = self.task(launchPath: "/usr/bin/ldid",arguments: "-S"+localPath+"/work_dir/Entitlements.xml",executablePath);
                                                self.log("entitlement write result: \(entitlementWriteResult)");
                                            }
                                            //print ("/usr/bin/ldid -K"+self.selfAppPath+"/Certificates.p12 "+executablePath);
                                            //let signResult = self.task(launchPath: "/usr/bin/ldid",arguments: "-K"+self.selfAppPath+"/Certificates.p12",executablePath);
                                            //print ("sign result: \(signResult)");
                                        } else {
                                            self.log("no executables in plist at location \(fileURL.absoluteString)")
                                        }
                                        
                                    } catch {
                                        self.log("error, unable to parse Info.plist");
                                    }
                                    let plist = PlistConverter(binaryData: plistData);
                                    
                                    let plistXML = plist?.convertToXML();
                                    
                                    
                                    let fixedXML = plistXML?.replacingOccurrences(of: mainBundleId, with: newBundleId)
                                    
                                    try fixedXML?.write(to: fileURL, atomically: true, encoding: .utf8);
                                }
                            }
                        } catch { self.log("\(error), \(fileURL)"); self.isAppCloningNow = false; }
                    }
                    //self.log(files)
                }
            } catch {
                self.log("Error parsing main Info.plist \(error)")
                self.setStatusText(text: "ERROR: unable to parse Info.plist")
                self.isAppCloningNow = false;
                return;
            }
            
            self.log("modified plists written zipping")
            do {
                let filePath = URL(string: localPath+"/work_dir/Payload")
                
                let zipFilePath = self.localPathURL.appendingPathComponent("archive.ipa")
                try Zip.zipFiles(paths: [filePath! as URL], zipFilePath: zipFilePath, password: nil, progress: { (progress) -> () in
                    self.log("\(progress)");
                    let percents = round(progress*100*100)/100;
                    self.setStatusText(text: "Archiving "+percents.description+"%");
                }) //Zip
                
                self.log("zipped!");
                
                
                
                // clearance
                do {
                    try FileManager.default.removeItem(atPath: localPath+"/work_dir/Payload")
                    
                } catch {
                    self.log("unable to remove temp dir \(error) we can give up on it");
                    //self.isAppCloningNow = false;
                    //self.setStatusText(text: "ERROR: unable to remove temp dir")
                    //return;
                }
                
                if separateBinary {
                    do {
                        try FileManager.default.removeItem(at: URL(string: "file:///var/mobile/Documents/CrackerXI/"+app.mainBundleExecutable!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!)
                    }catch {
                        self.log("unable to remove separate binary we can give up on it \(error)");
                        //self.isAppCloningNow = false;
                        //self.setStatusText(text: "ERROR: unable to remove temp dir")
                        //return;
                    }
                }
                
                
                
                self.setStatusText(text: "Requesting installation");
                
                
                DispatchQueue.main.async {
                    let appInstallUrl = "itms-services://?action=download-manifest&url=https%3A%2F%2Fduppy.app%2Fdownload.php%3Fname%3D"+newBundleId;
                    
                    self.log("app install URL is \(appInstallUrl)")
                    if let url = URL(string:appInstallUrl) {
                        UIApplication.shared.open(url)
                    }
                }
                self.setStatusText(text: "Duppied!\nDon't close this app until duplicate is installed");
                self.isAppCloningNow = false;
            }
            catch {
                self.log("Something went wrong")
                self.isAppCloningNow = false;
                self.setStatusText(text: "ERROR: something went wrong")
                return
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let appName = appModel[indexPath.row].mainBundleName! as String
        self.log("selected \(appName)")
        
        var refreshAlert: UIAlertController;
        
        if self.isAppCloningNow == true {
            refreshAlert = UIAlertController(title: "Not now", message: "Another app cloning is in progress", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction!) in
                self.log("Handle Cancel Logic here")
            }))
        } else {
            
            if appModel[indexPath.row].isDRM! {
                
                if (!FileManager.default.fileExists(atPath: "/var/mobile/Documents/CrackerXI/"+appModel[indexPath.row].mainBundleExecutable!)) {
                    
                    
                    refreshAlert = UIAlertController(title: "DRM-protected", message: "This app is iTunes DRM protected and no decrypted binary found in CrackerXI folder\nDump app binary (select \"YES, binary only\") with CrackerXI from https://cydia.iphonecake.com/ to clone this app", preferredStyle: UIAlertController.Style.alert)
                    
                    refreshAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction!) in
                        self.log("Handle Cancel Logic here")
                    }))
                } else {
                    refreshAlert = UIAlertController(title: "Clone \(appName) with DRM-free binary", message: "Please enter desired app name or leave blank to use original one. Don't worry, we will clear DRM-free binary once finished", preferredStyle: UIAlertController.Style.alert)
                    
                    refreshAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                        textField.placeholder = self.appModel[indexPath.row].mainBundleName! as String
                    })
                    
                    refreshAlert.addAction(UIAlertAction(title: "Clone", style: .default, handler: { (action: UIAlertAction!) in
                        let newBundleName = refreshAlert.textFields![0];
                        if newBundleName.text != "" {
                            self.appModel[indexPath.row].mainBundleName = newBundleName.text
                        }
                        self.cloneApp(app: self.appModel[indexPath.row],separateBinary:true)
                    }))
                    
                    refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                        self.log("Handle Cancel Logic here")
                    }))
                }
            } else {
                refreshAlert = UIAlertController(title: "Clone \(appName)", message: "Please enter desired app name or leave blank to use original one", preferredStyle: UIAlertController.Style.alert)
                
                refreshAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                    textField.placeholder = self.appModel[indexPath.row].mainBundleName! as String
                })
                
                refreshAlert.addAction(UIAlertAction(title: "Clone", style: .default, handler: { (action: UIAlertAction!) in
                    let newBundleName = refreshAlert.textFields![0];
                    if newBundleName.text != "" {
                        self.appModel[indexPath.row].mainBundleName = newBundleName.text
                    }
                    self.cloneApp(app: self.appModel[indexPath.row],separateBinary:false)
                }))
                
                refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    self.log("Handle Cancel Logic here")
                }))
            }
        }
        
        present(refreshAlert, animated: true, completion: nil)
    }
    @IBOutlet weak var appsTableView: UITableView!
    
    @IBOutlet weak var statusText: UILabel!
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    let appsPath = "/var/containers/Bundle/Application";
    var apps: [String: String] = [:];
    
    var appModel = [app]()
    
    override func viewDidLoad() {
        
        statusText.numberOfLines = 0;
        
        super.viewDidLoad()
        
        self.log("app path is \(self.selfAppPath)")
        self.log("documents path URL is \(self.localPathURL)");
        
        
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
                            let appObject = app(name: appDir, icon: mainBundleIcon, path: finalAppDir, mainBundleId: mainBundleId, mainBundleName: mainBundleName, isDRM:isDRM,mainBundleExecutable: mainBundleExecutable, mainBundleVersion: mainBundleVersion);
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
            
            appsTableView.dataSource = self;
            appsTableView.delegate = self;
            
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
    
    
}

extension URL {
    var fileSize: Int? { // in bytes
        do {
            let val = try self.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            return val.totalFileAllocatedSize ?? val.fileAllocatedSize
        } catch {
            print(error)
            return nil
        }
    }
}

extension FileManager {
    func directorySize(_ dir: URL) -> Int? { // in bytes
        if let enumerator = self.enumerator(at: dir, includingPropertiesForKeys: [], options: [], errorHandler: { (_, error) -> Bool in
            print(error)
            return false
        }) {
            var bytes = 0
            for case let url as URL in enumerator {
                bytes += url.fileSize ?? 0
            }
            return bytes
        } else {
            return nil
        }
    }
}
