//
//  PlistConverter.swift
//
//  Copyright (C) 2019 Bá-Anh Nguyễn <baanh.nguyen@outlook.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//
// * Tested OK on Swift 4+ *

import Foundation

open class PlistConverter {
    public struct PlistMimeType {
        static let xmlPlist    = "text/x-apple-plist+xml"
        static let binaryPlist = "application/x-apple-binary-plist"
    }
    
    //// Visible Stuffs ////////////////////////////////////////////////////////
    convenience init?(binaryData: Data) {
        self.init(binaryData, format: .binaryFormat_v1_0)
    }
    
    convenience init?(xml: String) {
        guard let xmlData = xml.data(using: .utf8) else { return nil }
        self.init(xmlData, format: .xmlFormat_v1_0)
    }
    
    open func convertToXML() -> String? {
        guard let xmlData = convert(to: .xmlFormat_v1_0) else { return nil }
        return String.init(data: xmlData, encoding: .utf8)
    }
    
    open func convertToBinary() -> Data? {
        return convert(to: .binaryFormat_v1_0)
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    //// Private ///////////////////////////////////////////////////////////////
    private var plist: CFPropertyList?                                        //
                                                                              //
    private init?(_ data: Data, format: CFPropertyListFormat) {               //
        var dataBytes = Array(data)                                           //
        let plistCoreData = CFDataCreate(kCFAllocatorDefault,                 //
                                         &dataBytes, dataBytes.count)         //
                                                                              //
        var error: Unmanaged<CFError>?                                        //
        var inputFormat = format                                              //
        let options = CFPropertyListMutabilityOptions                         //
                            .mutableContainersAndLeaves.rawValue              //
        plist = CFPropertyListCreateWithData(kCFAllocatorDefault,             //
                                             plistCoreData,                   //
                                             options,                         //
                                             &inputFormat,                    //
                                             &error)?.takeUnretainedValue()   //
        guard plist != nil, nil == error else {                               //
            print("Error on CFPropertyListCreateWithData : ",                 //
                  error!.takeUnretainedValue(), "Return nil")                 //
            error?.release()                                                  //
            return nil                                                        //
        }                                                                     //
        error?.release()                                                      //
    }                                                                         //
                                                                              //
    private func convert(to format: CFPropertyListFormat) -> Data? {          //
        var error: Unmanaged<CFError>?                                        //
        let binary = CFPropertyListCreateData(kCFAllocatorDefault,            //
                                              plist, format,                  //
                                              0, // unused, set 0             //
                                              &error)?.takeUnretainedValue()  //
        let data = Data.init(bytes: CFDataGetBytePtr(binary),                 //
                             count: CFDataGetLength(binary))                  //
        error?.release()                                                      //
        return data                                                           //
    }                                                                         //
                                                                              //
    ////////////////////////////////////////////////////////////////////////////
}
