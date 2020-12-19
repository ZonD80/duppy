//
//  AppInfoViewController.swift
//  CollectionApp
//
//  Created by ipodtouchdude on 07/06/2020.
//  Copyright © 2020 ipodtouchdude. All rights reserved.
//

import UIKit
import Zip
import Kingfisher

class AppInfoViewController: UIViewController {

    @IBOutlet var appIcon: UIImageView!
    @IBOutlet var appVersion: UILabel!
    @IBOutlet var appSize: UILabel!
    @IBOutlet var appID: UILabel!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var closeView: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    
    
    var appModel = [app]()
    
    var shapeLayer = CAShapeLayer()
    var pulsatingLayer: CAShapeLayer!
    var trackLayer:CAShapeLayer!
    let percentageLabel: UILabel = {
        let label = UILabel()
        label.text = "Duplicate"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        return label
    }()
    var duplicateCheck:Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func handleEnterForeground() {
        animatePulsatingLayer()
    }
    
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 100, startAngle: 0, endAngle:2 * CGFloat.pi, clockwise: true)
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 20
        layer.fillColor = fillColor.cgColor
        //layer.position = view.center
        return layer
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var center:CGPoint!
        
        if (UIScreen.main.bounds.size.height <= 667) {
            let location = view.frame.height - (view.frame.height/3)
            let location2 = location/2 - location
            let location3 = view.frame.height + location2
            center = CGPoint(x: view.center.x, y: location3)
        }
        else {
            let location = view.frame.height - (view.frame.height/2/2)
            let location2 = location/2 - location
            let location3 = view.frame.height + location2
            center = CGPoint(x: view.center.x, y: location3)
        }
        pulsatingLayer.position = center
        trackLayer.position = center
        shapeLayer.position = center
        percentageLabel.center = center
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        // Do any additional setup after loading the view.
        navBar.topItem?.title = appModel[0].mainBundleName!
        appVersion.text = appModel[0].mainBundleVersion!
        appID.adjustsFontSizeToFitWidth = true
        appID.minimumScaleFactor = 0.5
        appID.text = appModel[0].mainBundleId!
        if (appModel[0].icon == "noicon") {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                appIcon.kf.setImage(with: URL(fileURLWithPath:
                "/System/Library/PrivateFrameworks/MobileIcons.framework/DefaultIcon-60@2x~iphone.png"), placeholder: UIImage(named: "icon.png"))
            case .pad:
                appIcon.kf.setImage(with: URL(fileURLWithPath:
                "/System/Library/PrivateFrameworks/MobileIcons.framework/DefaultIcon-76@2x~ipad.png"), placeholder: UIImage(named: "icon.png"))
            case .tv:
                appIcon.image = nil
            case .carPlay:
                appIcon.image = nil
            case .unspecified:
                appIcon.image = nil
            @unknown default:
                appIcon.image = nil
            }
        }
        else {
            appIcon.kf.setImage(with: URL(fileURLWithPath: appModel[0].icon!), placeholder: UIImage(named: "icon.png"))
        }
        appIcon.layer.cornerRadius = 10
        appIcon.clipsToBounds = true
        
        let fm = FileManager.default
        let size = fm.directorySize(URL(fileURLWithPath: appModel[0].path!))
        appSize.text = humanReadableByteCount(bytes: size!)
        setupNotificationObservers()
        setupCircleLayers()
        setupPercentageLabel()
        closeView.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func humanReadableByteCount(bytes: Int) -> String {
        if (bytes < 1000) { return "\(bytes) B" }
        let exp = Int(log2(Double(bytes)) / log2(1000.0))
        let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
        let number = Double(bytes) / pow(1000, Double(exp))
        return String(format: "%.1f %@", number, unit)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        animatePulsatingLayer()
    }
    
    private func setupPercentageLabel() {
        view.addSubview(percentageLabel)
        percentageLabel.frame = CGRect(x: 0, y: 0, width: 130, height: 100)
        percentageLabel.center = view.center
    }
    
    private func setupCircleLayers() {
        //Pulsating layer
        pulsatingLayer = createCircleShapeLayer(strokeColor: UIColor.clear, fillColor: UIColor.pulsatingFillColor)
        view.layer.addSublayer(pulsatingLayer)
        animatePulsatingLayer()
        
        //Create my track layer
        trackLayer = createCircleShapeLayer(strokeColor: UIColor.trackStrokeColor, fillColor: UIColor.backgroundColor)
        view.layer.addSublayer(trackLayer)
        
        //Progress layer
        shapeLayer = createCircleShapeLayer(strokeColor: UIColor.outlineStrokeColor, fillColor: UIColor.clear)
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        view.layer.addSublayer(shapeLayer)
        //end
    }
    
    private func animatePulsatingLayer() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.3
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        pulsatingLayer.add(animation, forKey: "pulsing")
    }
    
    
    func disableView() {
        DispatchQueue.main.async {
            if self.duplicateCheck == false {
                if #available(iOS 13.0, *) {
                    self.isModalInPresentation = false
                }
                self.closeView.isHidden = false
            }
            else {
                if #available(iOS 13.0, *) {
                    self.isModalInPresentation = true
                }
                self.closeView.isHidden = true
            }
        }
    }
    
    @objc private func handleTap() {
        if duplicateCheck == false {
            let appName = appModel[0].mainBundleName! as String
            self.log("selected \(appName)")
            
            var refreshAlert: UIAlertController;
            
            if self.isAppCloningNow == true {
                refreshAlert = UIAlertController(title: "Not now", message: "Another app cloning is in progress", preferredStyle: UIAlertController.Style.alert)
                
                refreshAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction!) in
                    self.log("Handle Cancel Logic here")
                }))
            } else {
                
                if appModel[0].isDRM! {
                    
                    if (!FileManager.default.fileExists(atPath: "/var/mobile/Documents/CrackerXI/"+appModel[0].mainBundleExecutable!)) {
                        
                        
                        refreshAlert = UIAlertController(title: "DRM-protected", message: "This app is iTunes DRM protected and no decrypted binary found in CrackerXI folder\nDump app binary (select \"YES, binary only\") with CrackerXI from https://cydia.iphonecake.com/ to clone this app", preferredStyle: UIAlertController.Style.alert)
                        
                        refreshAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction!) in
                            self.log("Handle Cancel Logic here")
                        }))
                        
                        if appModel[0].trackId != "" {
                        refreshAlert.addAction(UIAlertAction(title: "Get DRM-free from appdb", style: .default, handler: { (action: UIAlertAction!) in
                            
                            let redirectURL = "https://appdb.to/view.php?trackid="+self.appModel[0].trackId!+"&type=ios";
                            self.log("redirecting to appdb to \(redirectURL)")
                            guard let url = URL(string: redirectURL) else { return }
                            UIApplication.shared.open(url)
                        }))
                        }
                    } else {
                        refreshAlert = UIAlertController(title: "Clone \(appName) with DRM-free binary", message: "Please enter desired app name or leave blank to use original one. Don't worry, we will clear DRM-free binary once finished", preferredStyle: UIAlertController.Style.alert)
                        
                        refreshAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                            textField.placeholder = self.appModel[0].mainBundleName! as String
                        })
                        
                        refreshAlert.addAction(UIAlertAction(title: "Clone", style: .default, handler: { (action: UIAlertAction!) in
                            let newBundleName = refreshAlert.textFields![0];
                            if newBundleName.text != "" {
                                self.appModel[0].mainBundleName = newBundleName.text
                            }
                            self.cloneApp(app: self.appModel[0],separateBinary:true)
                        }))
                        
                        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                            self.log("Handle Cancel Logic here")
                            self.percentageLabel.text = "Duplicate"
                            self.duplicateCheck = false
                            self.disableView()
                        }))
                        percentageLabel.text = "Starting"
                        duplicateCheck = true
                        disableView()
                    }
                } else {
                    refreshAlert = UIAlertController(title: "Clone \(appName)", message: "Please enter desired app name or leave blank to use original one", preferredStyle: UIAlertController.Style.alert)
                    
                    refreshAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                        textField.placeholder = self.appModel[0].mainBundleName! as String
                    })
                    
                    refreshAlert.addAction(UIAlertAction(title: "Clone", style: .default, handler: { (action: UIAlertAction!) in
                        let newBundleName = refreshAlert.textFields![0];
                        if newBundleName.text != "" {
                            self.appModel[0].mainBundleName = newBundleName.text
                        }
                        self.cloneApp(app: self.appModel[0],separateBinary:false)
                        
                    }))
                    
                    refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                        self.log("Handle Cancel Logic here")
                        self.percentageLabel.text = "Duplicate"
                        self.duplicateCheck = false
                        self.disableView()
                    }))
                    percentageLabel.text = "Starting"
                    duplicateCheck = true
                    disableView()
                }
            }
            
            present(refreshAlert, animated: true, completion: nil)
        }
        else {
            print("Something is downloading")
        }
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

    func log(_ text:String) {
        print("[Duppy] "+text);
        NSLog(text);
    }
    
    func setStatusText(text: String) {
        DispatchQueue.main.async {
            self.statusText.text = text;
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
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
                
                //newBundleId = "duppy."+self.randomString(length: mainBundleId.count-6); // make sure that new bundle ID has the same length
                newBundleId = mainBundleId+".duppy."+self.randomString(length: 6);
                
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
                                            /*let appGroupPatchResult = self.task(launchPath: "/usr/bin/perl", arguments: "-pi","-e", "s/"+mainBundleId+"/"+newBundleId+"/g",executablePath);
                                            self.log("binary patch result: \(appGroupPatchResult)");*/

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
                    
                    DispatchQueue.main.async {
                        self.percentageLabel.text = "\(Int(progress * 100))%"
                        self.shapeLayer.strokeEnd = CGFloat(progress)
                    }
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
                self.duplicateCheck = false
                self.disableView()
            }
            catch {
                self.log("Something went wrong")
                self.isAppCloningNow = false;
                self.setStatusText(text: "ERROR: something went wrong")
                return
            }
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
