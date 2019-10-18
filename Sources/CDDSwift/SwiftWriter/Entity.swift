//
//  Entity.swift
//  ios
//
//  Created by Alexei on 04/07/2019.
//  Copyright © 2019 Alexei. All rights reserved.
//

import Foundation

struct APIFieldD {
    var name: String
    var type: String
    var cases: [String] = []
    var isEnum: Bool {
        return cases.count > 0
    }
    var description: String?
    
    init(name: String,type: String) {
        let cleanType = type.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "?", with: "")
        var newType = ""
        if cleanType == "integer" {
            newType = "Int"
        }
        else if cleanType == "number" {
            newType = "Float"
        }
        else if cleanType == "boolean" {
            newType = "Bool"
        }
        else {
            newType = cleanType.capitalizingFirstLetter()
        }
        self.type = type.replacingOccurrences(of: cleanType, with: newType)
        self.name = name
    }
    
    var clearType: String {
        return type.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "?", with: "")
    }

    var isArray: Bool {
        return type.prefix(1) == "["
    }
    var isSimple: Bool {
        return ["String","Int","Float","Bool"].contains(clearType)
    }
}

struct APIRequestD {
    var path: String
    var method: String
    var fields: [APIFieldD]
    var responseType: String
    var errorType: String
    var description: String?
    var name: String {
        let name = path.components(separatedBy: ["/","\\","(",")"]).map {$0.capitalizingFirstLetter()}.joined()
        return name + "\(method.capitalizingFirstLetter())Request"
        
    }
}

struct APIModelD {
    var models: [APIModelD] = []
    var name: String
    var fields: [APIFieldD]
    var shouldBeUsedAsArray = false
    
    init(name:String,fields:[APIFieldD]) {
        self.name = name.capitalizingFirstLetter()
        self.fields = fields
    }
}


extension APIFieldD {
    func json() -> [String:Any] {
        return ["name":name,"type":type]
    }
    
    static func fromJson(_ json: [String:Any]) -> APIFieldD? {
        if let name = json["name"] as? String,
            let type = json["type"] as? String {
            return APIFieldD(name: name, type:type)
        }
        return nil
    }
}

extension APIModelD {
    func json() -> [String:Any] {
        return ["name":name,"fields":fields.map {$0.json()},"models":models.map {$0.json()}]
    }
    
    static func fromJson(_ json: [String:Any]) -> APIModelD? {
        if let name = json["name"] as? String {
            let fields = (json["fields"] as? [[String:Any]]) ?? []
            let models = (json["models"] as? [[String:Any]]) ?? []
            var model = APIModelD(name: name, fields: fields.compactMap {APIFieldD.fromJson($0)})
            model.models = models.compactMap {APIModelD.fromJson($0)}
            return model
        }
        return nil
    }
}

extension APIRequestD {
    func json() -> [String:Any] {
        return ["path":path,"method":method,"fields":fields.map {$0.json()}]
    }
    
    static func fromJson(_ json: [String:Any]) -> APIRequestD? {
        if let path = json["path"] as? String,
            let method = json["method"] as? String {
            let fields = (json["fields"] as? [[String:Any]]) ?? []
            let request = APIRequestD(path: path, method: method, fields: fields.compactMap {APIFieldD.fromJson($0)}, responseType: "", errorType: "", description: nil)
            return request
        }
        return nil
    }
}
