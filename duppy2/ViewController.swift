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
    
    @IBAction func buyCoffeeButtonTapped(_ sender: Any) {
        // Open Buy Me a Coffee URL in browser
        if let url = URL(string: "https://buymeacoffee.com/zond80") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func tapOtherAckButton(_ sender: Any) {
        guard let url = URL(string: "https://github.com/ZonD80/duppy/graphs/contributors") else { return }
        UIApplication.shared.open(url)
    }
    func log(_ text:String) {
        print("[Duppy] "+text);
        NSLog(text);
    }
    
    func findCommandPath(_ commandName: String) -> String? {
        let fileManager = FileManager.default
        
        // Define common base paths for different iOS environments
        let basePaths = [
            "/usr/bin",        // Standard iOS location
            "/var/jb/usr/bin", // Jailbroken device location
            "/bin",            // Alternative standard location
            "/var/jb/bin",     // Alternative jailbroken location
            "/usr/sbin",       // System admin commands
            "/var/jb/usr/sbin" // Jailbroken system admin commands
        ]
        
        // Check each base path + command combination
        for basePath in basePaths {
            let fullPath = "\(basePath)/\(commandName)"
            if fileManager.fileExists(atPath: fullPath) && fileManager.isExecutableFile(atPath: fullPath) {
                self.log("Duppy: Found \(commandName) at: \(fullPath)")
                return fullPath
            }
        }
        
        self.log("Duppy: Could not find \(commandName) in any of the common locations: \(basePaths.map { "\($0)/\(commandName)" })")
        return nil
    }
    
    func task(launchPath: String, arguments: String...) -> NSString {
        let task = NSTask.init()
        
        // Special check for ls command - use universal path detection
        let lsPath = findCommandPath("ls")
        
        if (launchPath != lsPath && lsPath != nil) {
            // Verify the program exists using ls
            let programExists = self.task(launchPath: lsPath!, arguments: launchPath)
                
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
    
    func ensureLdidExecutable() {
        let ldidPath = "\(selfAppPath)/ldid_iphoneos_arm64"
        
        self.log("Duppy: Checking ldid binary permissions at \(ldidPath)")
        
        // Check if file exists and is executable using FileManager
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: ldidPath)
        
        if !fileExists {
            self.log("Duppy: ldid binary not found at \(ldidPath)")
            return
        }
        
        let isExecutable = fileManager.isExecutableFile(atPath: ldidPath)
        
        if !isExecutable {
            self.log("Duppy: ldid binary is not executable, fixing permissions...")
            
            // Find chmod using universal path detection
            guard let validChmodPath = findCommandPath("chmod") else {
                return
            }
            
            // Make the binary executable using the found chmod path
            let chmodResult = self.task(launchPath: validChmodPath, arguments: "+x", ldidPath)
            
            // Verify it worked
            let verifyExecutable = fileManager.isExecutableFile(atPath: ldidPath)
            
            if verifyExecutable {
                self.log("Duppy: Successfully made ldid binary executable")
            } else {
                self.log("Duppy: Failed to make ldid binary executable with regular chmod - chmod result: \(chmodResult)")
                self.log("Duppy: Trying with sudo...")
                
                // Try with sudo - prompt for password
                self.promptForPasswordAndChmod(chmodPath: validChmodPath, ldidPath: ldidPath)
            }
        } else {
            self.log("Duppy: ldid binary is already executable")
        }
    }
    
    func promptForPasswordAndChmod(chmodPath: String, ldidPath: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Duppy: Root Access Required", 
                                        message: "Please enter your root password to make ldid executable:", 
                                        preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "Root password"
                textField.text = "alpine"  // Default jailbreak password
                textField.isSecureTextEntry = true
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                guard let password = alert.textFields?.first?.text, !password.isEmpty else {
                    self.log("Duppy: No password entered, cannot proceed with sudo chmod")
                    return
                }
                
                self.executeSudoChmod(password: password, chmodPath: chmodPath, ldidPath: ldidPath)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.log("Duppy: User cancelled password prompt, ldid binary remains non-executable")
            }
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true)
        }
    }
    
    func executeSudoChmod(password: String, chmodPath: String, ldidPath: String) {
        let fileManager = FileManager.default
        
        // First try FileManager approach since app might have permission to modify its own files
        self.log("Duppy: Trying FileManager setAttributes first...")
        do {
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try fileManager.setAttributes(attributes, ofItemAtPath: ldidPath)
            
            let checkExecutable = fileManager.isExecutableFile(atPath: ldidPath)
            if checkExecutable {
                self.log("Duppy: Successfully made ldid binary executable using FileManager")
                return
            }
        } catch {
            self.log("Duppy: FileManager setAttributes failed: \(error.localizedDescription)")
        }
        
        // If FileManager failed, try sudo approach
        self.log("Duppy: FileManager approach failed, trying sudo...")
        
        // Find sudo using universal path detection
        guard let validSudoPath = findCommandPath("sudo") else {
            return
        }
        
        // Use sudo with -S flag to read password from stdin
        self.log("Duppy: Executing sudo chmod +x with provided password...")
        
        // Find shell using universal path detection
        let shellPath = findCommandPath("sh")
        
        var sudoResult: NSString
        
        if let validShellPath = shellPath {
            // Use shell to pipe password to sudo
            let sudoCommand = "echo '\(password)' | '\(validSudoPath)' -S '\(chmodPath)' +x '\(ldidPath)'"
            sudoResult = self.task(launchPath: validShellPath, arguments: "-c", sudoCommand)
        } else {
            self.log("Duppy: No shell found, trying direct sudo execution...")
            // Try direct sudo execution without shell (this might not work for password input)
            sudoResult = self.task(launchPath: validSudoPath, arguments: "-S", chmodPath, "+x", ldidPath)
        }
        
        // Verify it worked
        let verifyExecutable = fileManager.isExecutableFile(atPath: ldidPath)
        
        if verifyExecutable {
            self.log("Duppy: Successfully made ldid binary executable using sudo")
        } else {
            self.log("Duppy: All methods failed - ldid binary remains non-executable - sudo result: \(sudoResult)")
        }
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
    
    // Server management
    private var httpServer: HttpServer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override func viewDidLoad() {
        
        statusText.numberOfLines = 0;
        
        super.viewDidLoad()
        
        self.log("app path is \(self.selfAppPath)")
        self.log("documents path URL is \(self.localPathURL)");
        
        // Ensure ldid binary is executable at app startup
        ensureLdidExecutable()
        
        // Setup app lifecycle observers for server management
        setupAppLifecycleObservers()
        
        //let perlTestResult = self.task(launchPath: findCommandPath("perl") ?? "/usr/bin/perl",arguments: "-v");
            
            if (false/*!perlTestResult.contains("This is perl")*/) {
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
                                // Improved icon detection with directory scanning
                                mainBundleIcon = findAppIcon(appPath: finalAppDir, plistEntities: mainInfoPlistEntities)
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
            
            // Start HTTP server with improved reliability
            startHttpServer()
            
            
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
    
    // MARK: - Server Management
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func startHttpServer() {
        guard httpServer == nil else {
            self.log("Duppy: HTTP server already running")
            return
        }
        
        let localPath = localPathURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        // Use .userInteractive QoS for maximum performance during downloads
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            let server = HttpServer()
            
            // Configure server routes
            server["/"] = { request in
                return HttpResponse.ok(.text("OK"))
            }
            server["/download/:path"] = self.createProgressTrackingFileHandler(basePath: localPath)
            
            do {
                try server.start(44443, forceIPv4: true)
                
                // Keep strong reference to server
                DispatchQueue.main.async {
                    self.httpServer = server
                }
                
                self.log("Duppy: HTTP server started successfully on port \(try server.port())")
                self.log("Duppy: Server state: \(server.state)")
                
            } catch {
                self.log("Duppy: HTTP server start error: \(error)")
                
                // Try alternative port if 44443 is busy
                do {
                    try server.start(0, forceIPv4: true) // Use random available port
                    DispatchQueue.main.async {
                        self.httpServer = server
                    }
                    self.log("Duppy: HTTP server started on alternative port \(try server.port())")
                } catch {
                    self.log("Duppy: Failed to start HTTP server on any port: \(error)")
                }
            }
        }
    }
    
    private func stopHttpServer() {
        httpServer?.stop()
        httpServer = nil
        self.log("Duppy: HTTP server stopped")
    }
    
    @objc private func handleAppDidEnterBackground() {
        self.log("Duppy: App entering background - starting background task")
        startBackgroundTask()
    }
    
    @objc private func handleAppWillEnterForeground() {
        self.log("Duppy: App entering foreground - ending background task")
        endBackgroundTask()
        
        // Restart server if it was stopped
        if httpServer == nil {
            self.log("Duppy: Restarting HTTP server")
            startHttpServer()
        }
    }
    
    private func startBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DuppyHTTPServer") { [weak self] in
            self?.log("Duppy: Background task expired")
            self?.endBackgroundTask()
        }
        
        if backgroundTask == .invalid {
            self.log("Duppy: Failed to start background task")
        } else {
            self.log("Duppy: Background task started")
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        self.log("Duppy: Background task ended")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopHttpServer()
        endBackgroundTask()
    }
    
    // MARK: - Icon Detection
    
    private func findAppIcon(appPath: String, plistEntities: NSDictionary) -> String {
        self.log("Duppy: Scanning for app icon in \(appPath)")
        
        // Method 1: Try CFBundleIcons from Info.plist (current approach, but with validation)
        if let iconPath = tryPlistIconDetection(appPath: appPath, plistEntities: plistEntities) {
            return iconPath
        }
        
        // Method 2: Try app-name-based icon patterns
        if let iconPath = tryAppNameBasedIcons(appPath: appPath, plistEntities: plistEntities) {
            return iconPath
        }
        
        // Method 3: Scan directory for common icon patterns
        if let iconPath = scanDirectoryForIcons(appPath: appPath) {
            return iconPath
        }
        
        // Method 4: Check for legacy icon patterns
        if let iconPath = tryLegacyIconPatterns(appPath: appPath) {
            return iconPath
        }
        
        self.log("Duppy: No app icon found for \(appPath)")
        
        // Enable debug logging for problematic apps to help identify missing icons
        debugListDirectoryContents(appPath: appPath)
        
        return "noicon"
    }
    
    private func tryPlistIconDetection(appPath: String, plistEntities: NSDictionary) -> String? {
        guard let bundleIcons = plistEntities["CFBundleIcons"] as? NSDictionary,
              let primaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? NSDictionary,
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? NSArray else {
            return nil
        }
        
        // Try all icon names from the plist, not just the last one
        for iconName in iconFiles.reversed() {
            guard let iconName = iconName as? String else { continue }
            
            // Try different resolutions and suffixes
            let possiblePaths = [
                "\(appPath)/\(iconName)@3x.png",
                "\(appPath)/\(iconName)@2x.png", 
                "\(appPath)/\(iconName).png",
                "\(appPath)/\(iconName)@3x",
                "\(appPath)/\(iconName)@2x",
                "\(appPath)/\(iconName)"
            ]
            
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    self.log("Duppy: Found icon from plist: \(path)")
                    return path
                }
            }
        }
        
        return nil
    }
    
    private func tryAppNameBasedIcons(appPath: String, plistEntities: NSDictionary) -> String? {
        // Try to use the app's display name or bundle name to find icons
        var appNames: [String] = []
        
        if let displayName = plistEntities["CFBundleDisplayName"] as? String {
            appNames.append(displayName)
        }
        if let bundleName = plistEntities["CFBundleName"] as? String {
            appNames.append(bundleName)
        }
        if let bundleId = plistEntities["CFBundleIdentifier"] as? String {
            // Extract app name from bundle ID (e.g., com.example.MyApp -> MyApp)
            if let lastComponent = bundleId.components(separatedBy: ".").last {
                appNames.append(lastComponent)
            }
        }
        
        // Also try the app directory name
        let appDirName = URL(fileURLWithPath: appPath).lastPathComponent
        if appDirName.hasSuffix(".app") {
            let nameWithoutExtension = String(appDirName.dropLast(4))
            appNames.append(nameWithoutExtension)
        }
        
        // Remove duplicates and empty names
        let uniqueNames = Array(Set(appNames)).filter { !$0.isEmpty }
        
        for appName in uniqueNames {
            let patterns = [
                "\(appName)@3x.png", "\(appName)@2x.png", "\(appName).png",
                "\(appName)_icon@3x.png", "\(appName)_icon@2x.png", "\(appName)_icon.png",
                "\(appName)-icon@3x.png", "\(appName)-icon@2x.png", "\(appName)-icon.png",
                "icon_\(appName)@3x.png", "icon_\(appName)@2x.png", "icon_\(appName).png",
                "icon-\(appName)@3x.png", "icon-\(appName)@2x.png", "icon-\(appName).png",
            ]
            
            for pattern in patterns {
                let iconPath = "\(appPath)/\(pattern)"
                if FileManager.default.fileExists(atPath: iconPath) {
                    self.log("Duppy: Found app-name-based icon: \(iconPath)")
                    return iconPath
                }
            }
        }
        
        return nil
    }
    
    private func scanDirectoryForIcons(appPath: String) -> String? {
        // Scan main directory first
        if let iconPath = scanSingleDirectoryForIcons(appPath: appPath) {
            return iconPath
        }
        
        // Check subdirectories that might contain icons
        let possibleIconDirs = ["Icons", "icons", "Images", "images", "Assets", "assets"]
        for iconDir in possibleIconDirs {
            let subdirPath = "\(appPath)/\(iconDir)"
            if FileManager.default.fileExists(atPath: subdirPath) {
                if let iconPath = scanSingleDirectoryForIcons(appPath: subdirPath) {
                    return iconPath
                }
            }
        }
        
        // Scan .car files (iOS Asset Catalogs) - this is more complex but we can try
        if let iconPath = scanForCarAssets(appPath: appPath) {
            return iconPath
        }
        
        return nil
    }
    
    private func scanSingleDirectoryForIcons(appPath: String) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: appPath)
            
            // Common icon patterns to look for (in order of preference)
            let iconPatterns = [
                // High resolution first
                "AppIcon60x60@3x.png", "AppIcon76x76@3x.png", "AppIcon83.5x83.5@2x.png",
                "AppIcon60x60@2x.png", "AppIcon76x76@2x.png", "AppIcon40x40@3x.png",
                "AppIcon40x40@2x.png", "AppIcon29x29@3x.png", "AppIcon29x29@2x.png",
                // Generic patterns
                "AppIcon@3x.png", "AppIcon@2x.png", "AppIcon.png",
                "Icon@3x.png", "Icon@2x.png", "Icon.png", 
                "icon@3x.png", "icon@2x.png", "icon.png",
                // Alternative naming
                "Icon-60@3x.png", "Icon-60@2x.png", "Icon-76@2x.png", "Icon-76.png",
                "Icon-Small-40@3x.png", "Icon-Small-40@2x.png", "Icon-Small@3x.png", "Icon-Small@2x.png",
                // Without extensions
                "AppIcon60x60@3x", "AppIcon76x76@3x", "AppIcon83.5x83.5@2x",
                "AppIcon60x60@2x", "AppIcon76x76@2x", "AppIcon40x40@3x",
                "AppIcon40x40@2x", "AppIcon29x29@3x", "AppIcon29x29@2x",
                "AppIcon@3x", "AppIcon@2x", "AppIcon",
                "Icon@3x", "Icon@2x", "Icon",
                "icon@3x", "icon@2x", "icon"
            ]
            
            // Check for exact matches first
            for pattern in iconPatterns {
                if contents.contains(pattern) {
                    let iconPath = "\(appPath)/\(pattern)"
                    self.log("Duppy: Found icon by pattern matching: \(iconPath)")
                    return iconPath
                }
            }
            
            // Check for files that contain icon-related keywords
            let iconKeywords = ["icon", "Icon", "AppIcon", "appicon", "logo", "Logo"]
            for file in contents {
                let lowercaseFile = file.lowercased()
                for keyword in iconKeywords {
                    if lowercaseFile.contains(keyword.lowercased()) && 
                       (lowercaseFile.hasSuffix(".png") || lowercaseFile.hasSuffix(".jpg") || lowercaseFile.hasSuffix(".jpeg") || !lowercaseFile.contains(".")) {
                        let iconPath = "\(appPath)/\(file)"
                        self.log("Duppy: Found icon by keyword search: \(iconPath)")
                        return iconPath
                    }
                }
            }
            
            // Last resort: look for any .png files that might be icons
            let imageFiles = contents.filter { file in
                let lowercaseFile = file.lowercased()
                return lowercaseFile.hasSuffix(".png") || lowercaseFile.hasSuffix(".jpg") || lowercaseFile.hasSuffix(".jpeg")
            }
            
            // Sort by file size (icons are usually medium-sized, not tiny or huge)
            let sortedImages = imageFiles.compactMap { fileName -> (String, Int)? in
                let filePath = "\(appPath)/\(fileName)"
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                      let fileSize = attributes[.size] as? Int else { return nil }
                return (fileName, fileSize)
            }.sorted { $0.1 > $1.1 } // Sort by size descending
            
            // Try the largest reasonable image files (likely icons)
            for (fileName, fileSize) in sortedImages {
                // Skip very small files (likely not icons) and very large files (likely screenshots)
                if fileSize > 1000 && fileSize < 500000 { // 1KB to 500KB range
                    let iconPath = "\(appPath)/\(fileName)"
                    self.log("Duppy: Found potential icon by size analysis: \(iconPath) (\(fileSize) bytes)")
                    return iconPath
                }
            }
            
        } catch {
            self.log("Duppy: Error scanning directory for icons: \(error)")
        }
        
        return nil
    }
    
    private func scanForCarAssets(appPath: String) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: appPath)
            let carFiles = contents.filter { $0.hasSuffix(".car") }
            
            for carFile in carFiles {
                // .car files are binary asset catalogs - we can't easily extract from them
                // but we can note their presence for debugging
                self.log("Duppy: Found .car asset catalog: \(carFile) (extraction not implemented)")
            }
        } catch {
            self.log("Duppy: Error scanning for .car assets: \(error)")
        }
        
        return nil
    }
    
    private func tryLegacyIconPatterns(appPath: String) -> String? {
        // Try some legacy iOS icon patterns and common alternatives
        let legacyPatterns = [
            // iTunes artwork
            "iTunesArtwork@2x.png", "iTunesArtwork.png",
            // Default launch images (might be used as icons)
            "Default@3x.png", "Default@2x.png", "Default.png",
            "Default-568h@2x.png", "Default-667h@2x.png", "Default-736h@3x.png",
            // Common alternative patterns
            "app_icon.png", "app_icon@2x.png", "app_icon@3x.png",
            "application_icon.png", "application_icon@2x.png",
            "logo.png", "logo@2x.png", "logo@3x.png",
            // Bundle display name based icons
            "icon_large.png", "icon_medium.png", "icon_small.png"
        ]
        
        for pattern in legacyPatterns {
            let iconPath = "\(appPath)/\(pattern)"
            if FileManager.default.fileExists(atPath: iconPath) {
                self.log("Duppy: Found legacy/alternative icon: \(iconPath)")
                return iconPath
            }
        }
        
        return nil
    }
    
    // Debug function to help identify what files are actually in the app directory
    private func debugListDirectoryContents(appPath: String) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: appPath)
            self.log("Duppy: Directory contents for \(appPath):")
            for file in contents.prefix(20) { // Only show first 20 files to avoid log spam
                let filePath = "\(appPath)/\(file)"
                if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let fileSize = attributes[.size] as? Int {
                    self.log("Duppy:   - \(file) (\(fileSize) bytes)")
                } else {
                    self.log("Duppy:   - \(file)")
                }
            }
            if contents.count > 20 {
                self.log("Duppy:   ... and \(contents.count - 20) more files")
            }
        } catch {
            self.log("Duppy: Could not list directory contents: \(error)")
        }
    }
    
    // MARK: - Progress Tracking File Handler
    
    private func createProgressTrackingFileHandler(basePath: String) -> ((HttpRequest) -> HttpResponse) {
        return { [weak self] request in
            guard let self = self,
                  let fileName = request.params[":path"] else {
                return HttpResponse.notFound
            }
            
            let filePath = "\(basePath)/\(fileName)"
            
            guard FileManager.default.fileExists(atPath: filePath) else {
                self.log("Duppy: File not found: \(filePath)")
                return HttpResponse.notFound
            }
            
            do {
                let fileURL = URL(fileURLWithPath: filePath)
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
                let totalBytes = Int64(fileAttributes[.size] as? UInt64 ?? 0)
                
                self.log("Duppy: Starting optimized download for \(fileName) (\(totalBytes) bytes)")
                
                // Send initial progress notification
                NotificationCenter.default.post(name: NSNotification.Name("DownloadProgress"), object: nil, userInfo: [
                    "fileName": fileName,
                    "bytesWritten": Int64(0),
                    "totalBytes": totalBytes
                ])
                
                // Use streaming approach for better memory efficiency and speed
                return self.createOptimizedStreamingResponse(fileName: fileName, filePath: filePath, totalBytes: totalBytes)
                
            } catch {
                self.log("Duppy: Error accessing file \(fileName): \(error)")
                return HttpResponse.internalServerError
            }
        }
    }
    
    private func createOptimizedStreamingResponse(fileName: String, filePath: String, totalBytes: Int64) -> HttpResponse {
        // Optimized headers for maximum streaming performance
        let headers = [
            "Content-Type": "application/octet-stream",
            "Content-Length": "\(totalBytes)",
            "Accept-Ranges": "bytes",
            "Cache-Control": "no-cache, no-store",
            "Connection": "keep-alive",
            "Transfer-Encoding": "identity"
        ]
        
        return HttpResponse.raw(200, "OK", headers) { [weak self] writer in
            
            // Larger chunks for maximum throughput (512KB for very fast streaming)
            let chunkSize = 524288 // 512KB chunks
            var bytesSent: Int64 = 0
            let totalChunks = Int((totalBytes + Int64(chunkSize) - 1) / Int64(chunkSize))
            
            // Minimal notification frequency for maximum speed
            let notificationInterval = max(1, totalChunks / 50) // Only 50 progress updates max
            
            self?.log("Duppy: Ultra-fast streaming \(fileName) in \(totalChunks) chunks of \(chunkSize/1024)KB")
            
            guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
                self?.log("Duppy: Could not open file handle for \(fileName)")
                return
            }
            
            defer {
                fileHandle.closeFile()
            }
            
            // Stream directly from file without loading into memory
            for chunkIndex in 0..<totalChunks {
                autoreleasepool {
                    let currentChunkSize = min(chunkSize, Int(totalBytes - bytesSent))
                    
                    // Read chunk directly from file
                    let chunk = fileHandle.readData(ofLength: currentChunkSize)
                    
                    if chunk.isEmpty {
                        self?.log("Duppy: Reached end of file at chunk \(chunkIndex)")
                        return
                    }
                    
                    // Write chunk immediately for maximum speed
                    do {
                        try writer.write([UInt8](chunk))
                        bytesSent += Int64(chunk.count)
                        
                        // Minimal progress notifications to reduce overhead
                        if chunkIndex % notificationInterval == 0 || chunkIndex == totalChunks - 1 {
                            NotificationCenter.default.post(name: NSNotification.Name("DownloadProgress"), object: nil, userInfo: [
                                "fileName": fileName,
                                "bytesWritten": bytesSent,
                                "totalBytes": totalBytes
                            ])
                        }
                        
                    } catch {
                        self?.log("Duppy: Error writing chunk \(chunkIndex) for \(fileName): \(error)")
                        return
                    }
                }
            }
            
            // Send completion notification
            if bytesSent >= totalBytes {
                self?.log("Duppy: Ultra-fast download completed for \(fileName) (\(bytesSent)/\(totalBytes) bytes)")
                NotificationCenter.default.post(name: NSNotification.Name("DownloadCompleted"), object: nil, userInfo: [
                    "fileName": fileName,
                    "bytesWritten": bytesSent,
                    "totalBytes": totalBytes
                ])
            }
        }
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
