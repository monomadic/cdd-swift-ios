//
//  Project.swift
//  Basic
//
//  Created by Rob Saunders on 7/6/19.
//

import Foundation

struct Settings {
    let host: URL
}

protocol ProjectObject {
    var name: String {get}
}

enum SequenseCompareResult<T> {
    case insertion(T)
    case deletion(T)
    case same(T)
    
    func object() -> T {
        switch self {
        case .insertion(let object):
            return object
        case .deletion(let object):
            return object
        case .same(let object):
            return object
        }
    }
}

extension Array where Element: ProjectObject {
    func replaceWith(newestItems: Array<Element>) -> [Element] {
        var newArray:[Element] = self
        for item in newestItems {
            if let index = self.firstIndex(where: {$0.name == item.name}) {
                newArray[index] = item
            }
            else {
                newArray.append(item)
            }
        }
        return newArray
    }
    
    func compare(to oldArray: Array<Element>) -> [SequenseCompareResult<Element>] {
        var result: [SequenseCompareResult<Element>] = []
        var oldArray = oldArray
        
        for object in self {
            if let index = oldArray.firstIndex(where: {$0.name == object.name}) {
                oldArray.remove(at: index)
                result.append(.same(object))
            }
            else {
                result.append(.insertion(object))
            }
        }
        
        result.append(contentsOf:oldArray.map { .deletion($0) })
        return result
    }
}

struct Project: Codable {
	var info: ProjectInfo
	var models: [Model]
	var requests: [Request]
    
    func merge(with swiftProject: Project) -> Project {
        var newSwiftModels = swiftProject.models
        newSwiftModels.removeAll(where: {$0.modificationDate.compare(info.modificationDate) == .orderedAscending})
        let mergedModels = models.replaceWith(newestItems: newSwiftModels)
        
        var newSwiftRequests = swiftProject.requests
        newSwiftRequests.removeAll(where: {$0.modificationDate.compare(info.modificationDate) == .orderedAscending})
        let mergedRequests = requests.replaceWith(newestItems: newSwiftRequests)
        
        return Project(
            info: self.info.merge(with: swiftProject.info),
            models: mergedModels,
            requests: mergedRequests
        )
        
    }
}


extension Decodable {
    static func from(json: String) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

extension Encodable {
    func json() throws -> String {
        let data = try JSONEncoder().encode(self)
        
        return String(data: data, encoding: .utf8) ?? ""
    }
}











