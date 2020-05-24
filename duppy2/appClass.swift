//
//  appClass.swift
//  duppy2
//
//  Created by ZonD Eighty on 23.05.2020.
//  Copyright © 2020 appdb. All rights reserved.
//

import UIKit


class app:NSObject{

    var name:String?
    var path : String?
    var mainBundleId: String?
    var mainBundleName: String?
    var mainBundleExecutable: String?
    var isDRM: Bool?
    
    init(name:String,path:String,mainBundleId:String,mainBundleName:String,isDRM:Bool,mainBundleExecutable:String) {
        self.name = name;
        self.path = path;
        self.mainBundleId = mainBundleId;
        self.mainBundleName = mainBundleName;
        self.isDRM = isDRM;
        self.mainBundleExecutable = mainBundleExecutable;
    }
}
