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

class ViewController: UIViewController , UITableViewDataSource , UITableViewDelegate {
    

    
    let localPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
    var isAppCloningNow: Bool = false;
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appModel.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x:0, y:0, width:UIScreen.main.fixedCoordinateSpace.bounds.width, height:50))
        label.numberOfLines = 0;
        label.text = "\(appModel[indexPath.row].mainBundleName! as String)\n\(appModel[indexPath.row].name! as String)";
        
        cell.addSubview(label)
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func setStatusText(text: String) {
        DispatchQueue.main.async {
            self.statusText.text = text;
        }
    }
    
    func cloneApp(app: app) {
        
        self.isAppCloningNow = true;
        
        self.setStatusText(text: "Starting to clone");
        
        let localPath = localPathURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        let archiverQueue = DispatchQueue(label: "archiver")
        archiverQueue.async {
            
            let appName = app.name! as String;
            let appPath = app.path! as String;
            print("cloning \(appName) at path \(appPath)")
            print("clearing temp dir: "+localPath+"/work_dir/Payload")
            
            do {
                try FileManager.default.removeItem(atPath: localPath+"/work_dir/Payload")
            } catch {
                print("unable to remove temp dir \(error) we can give up on it");
                //self.isAppCloningNow = false;
                //self.setStatusText(text: "ERROR: unable to remove temp dir")
                //return;
            }
            do {
                try FileManager.default.createDirectory(atPath: localPath+"/work_dir/Payload", withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("unable to create temp dir \(error)");
                self.isAppCloningNow = false;
                self.setStatusText(text: "ERROR: unable to create temp dir")
                return;
            }
            
            print("Copying app data")
            
            self.setStatusText(text: "Copying original app data");
            
            do { try FileManager.default.copyItem(at: URL(string: "file://"+appPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!, to: URL(string: "file://"+localPath+"/work_dir/Payload/\(appName)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!)
            }
            catch {
                print("unable to copy dir \(error)");
                self.setStatusText(text: "ERROR: unable to remove temp dir")
                self.isAppCloningNow = false;
                return;
            }
            
            print("App data copied")
            
            self.setStatusText(text: "Making some magic");
            
            print("Searching for PLISTS and converting them to XML formats")
            
            let url = URL(fileURLWithPath: localPath+"/work_dir/Payload")
            
            let mainInfoPlistURL = URL(fileURLWithPath: localPath+"/work_dir/Payload/\(appName)/Info.plist");
            
            var newBundleId:String="";
            
            do {
                let mainInfoPlistEntities = try PropertyListSerialization.propertyList(from: Data(contentsOf: mainInfoPlistURL), options: [], format: nil) as! NSMutableDictionary

                let mainBundleId = mainInfoPlistEntities["CFBundleIdentifier"] as! String
                print("Main bundle id is \(mainBundleId)")
                
                newBundleId = "duppy."+self.randomString(length: 5)+"."+mainBundleId;

                print("Replacement bundle id is \(newBundleId)")
                
                mainInfoPlistEntities["CFBundleDisplayName"] = app.mainBundleName;
                
                do { try mainInfoPlistEntities.write(to: mainInfoPlistURL);
                    
                }
                catch {
                    print("unable to write to info plist")
                    self.setStatusText(text: "Unable to write to Info.plist")
                    return;
                }
                
                
                var files = [URL]()
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [], options: []) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                            if fileAttributes.isRegularFile! {
                                if fileURL.absoluteString.hasSuffix("Info.plist") {
                                    let plistData = try Data(contentsOf: fileURL);
                                    let plist = PlistConverter(binaryData: plistData);
                                    
                                    let plistXML = plist?.convertToXML();
                                    let fixedXML = plistXML?.replacingOccurrences(of: mainBundleId, with: newBundleId)
                                    
                                    try fixedXML?.write(to: fileURL, atomically: true, encoding: .utf8);
                                    
                                    //files.append(fileURL)
                                }
                            }
                        } catch { print(error, fileURL); self.isAppCloningNow = false; }
                    }
                    //print(files)
                }
            } catch {
                print("Error parsing main Info.plist")
                self.setStatusText(text: "ERROR: unable to parse Info.plist")
                self.isAppCloningNow = false;
                return;
            }
            
            print("modified plists written zipping")
            do {
                let filePath = URL(string: localPath+"/work_dir/Payload")

                let zipFilePath = self.localPathURL.appendingPathComponent("archive.ipa")
                try Zip.zipFiles(paths: [filePath! as URL], zipFilePath: zipFilePath, password: nil, progress: { (progress) -> () in
                    print(progress)
                    let percents = round(progress*100*100)/100;
                    self.setStatusText(text: "Archiving "+percents.description+"%");
                }) //Zip
                
                print ("zipped!");

                
                self.setStatusText(text: "Requesting installation");
                
                
                DispatchQueue.main.async {
                    let appInstallUrl = "itms-services://?action=download-manifest&url=https%3A%2F%2Fduppy.app%2Fdownload.php%3Fname%3D"+newBundleId;
                    
                    print("app install URL is \(appInstallUrl)")
                    if let url = URL(string:appInstallUrl) {
                        UIApplication.shared.open(url)
                    }
                }
                self.setStatusText(text: "Duppied!\nDon't close this app till duplicate be installed");
                self.isAppCloningNow = false;
            }
            catch {
              print("Something went wrong")
                self.isAppCloningNow = false;
                self.setStatusText(text: "ERROR: something went wrong")
                return
            }
        }
    }
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appName = appModel[indexPath.row].name! as String
        print("selected \(appName)")
        
        var refreshAlert: UIAlertController;
        
        if self.isAppCloningNow == true {
            refreshAlert = UIAlertController(title: "Not now", message: "Another app cloning is in progress", preferredStyle: UIAlertController.Style.alert)

            refreshAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction!) in
                  print("Handle Cancel Logic here")
            }))
        } else {
        refreshAlert = UIAlertController(title: "Clone \(appName)", message: "Please anter desired app name or leave blank to use original one", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                textField.placeholder = self.appModel[indexPath.row].mainBundleName! as String
            })

        refreshAlert.addAction(UIAlertAction(title: "Clone", style: .default, handler: { (action: UIAlertAction!) in
            let newBundleName = refreshAlert.textFields![0];
            if newBundleName.text != "" {
                self.appModel[indexPath.row].mainBundleName = newBundleName.text
            }
            self.cloneApp(app: self.appModel[indexPath.row])
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
        }))
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
        
        
        do {
            let appDirs = try FileManager.default.contentsOfDirectory(atPath: self.appsPath)

            //print("apps dirs are \(appDirs)")
            
            appDirs.forEach { appUUIDDir in
                do {
                    let appDirContents = try FileManager.default.contentsOfDirectory(atPath: "\(appsPath)/\(appUUIDDir)");
                    //print ("app dir contents are \(appDirContents)");
                    
                        appDirContents.forEach { appDir in
                            if appDir.hasSuffix(".app") {
                                let finalAppDir = "\(appsPath)/\(appUUIDDir)/\(appDir)";
                                //print("found final app dir \(finalAppDir)");
                                apps[appDir] = finalAppDir;
                                
                                let mainInfoPlistURL = URL(fileURLWithPath: "\(finalAppDir)/Info.plist");
                                
                                var mainBundleId:String = appDir;
                                var mainBundleName:String = appDir;
                                
                                do {
                                    let mainInfoPlistEntities = try PropertyListSerialization.propertyList(from: Data(contentsOf: mainInfoPlistURL), options: [], format: nil) as! NSDictionary
                                    
                                    print("display name is :\(mainInfoPlistEntities["CFBundleDisplayName"])");

                                    mainBundleId = mainInfoPlistEntities["CFBundleIdentifier"] as! String
                                    if (mainBundleId.hasPrefix("com.apple.")) {
                                        // it's apple software
                                        return;
                                    }
                                    if mainInfoPlistEntities["CFBundleDisplayName"] != nil {
                                        mainBundleName = mainInfoPlistEntities["CFBundleDisplayName"] as! String
                                    }
                                } catch {
                                    print("Unable to get app name")
                                }
                                let appObject = app(name: appDir, path: finalAppDir, mainBundleId: mainBundleId, mainBundleName: mainBundleName);
                                appModel.append(appObject);
                                return;
                            }
                        }
                    statusText.text = "Apps loaded\nTap on app to clone it";
                }
                catch {
                    print("unable to get contents of app dir \(error)");
                }
            }
            
            appsTableView.dataSource = self;
            appsTableView.delegate = self;

            let localPath = localPathURL.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            print ("local path is \(localPath)");
            
            DispatchQueue.global(qos: .background).async {
                let server = HttpServer()
                server["/"] = { request in
                    return HttpResponse.ok(.text("OK"))
                }
                server["/download/:path"]  = shareFilesFromDirectory(localPath);
                //server["/test"] =
                do {
                  try server.start(44443, forceIPv4: true)
                  print("Server has started ( port = \(try server.port()) ). Try to connect now...")
                    print("\(server.state)");
                    //semaphore.wait()
                } catch {
                  print("Server start error: \(error)")
                    //semaphore.signal()
                }
            }
            
            
        } catch {
            print("unable to get app dirs \(error)");
            self.setStatusText(text: "Looks like your device is not jailbroken")
        }
        
    }


}
