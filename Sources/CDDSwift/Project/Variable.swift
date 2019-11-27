//
//  Variable.swift
//  CYaml
//
//  Created by Rob Saunders on 7/16/19.
//

import Foundation

struct Variable: ProjectObject, Codable {
	let name: String
	var optional: Bool
	var type: Type
	var value: String?
	var description: String?

	init(name: String) {
		self.name = name
		optional = false
		type = .primitive(.String)
	}

	func find(in variables: [Variable]) -> Variable? {
		return variables.first(where: {
			self.name == $0.name
		})
	}
}

indirect enum Type: Equatable, Codable {
    case primitive(PrimitiveType)
    case array(Type)
    case complex(String)
    
    enum CodingKeys: String, CodingKey {
        case Array
        case Complex
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .primitive(let type):
            try type.encode(to: encoder)
//            try container.encode(type, forKey: .primitive)
        case .array(let type):
//            let str = try type.json()
//            try ("[" + str + "]").encode(to: encoder)
            try container.encode(type, forKey: .Array)
        case .complex(let type):
//            try type.encode(to: encoder)
            try container.encode(type, forKey: .Complex)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        if let str = try? container?.decode(String.self) {
            self = Type.decode(str:str)
        }
        else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let type = try? container.decode(String.self, forKey: .Complex) {
                self = .array(Type.decode(str: type))
            }
            else
            if let type = try? container.decode(String.self, forKey: .Array) {
                self = .array(Type.decode(str: type))
            }
            else
            if let type = try? container.decode(Type.self, forKey: .Array) {
                self = .array(type)
            }
            else {
                self = .complex("unknown")
            }
        }
        
    }
    
    private static func decode(str: String) -> Type {
//        var str = str
        switch str {
        case "Int": return .primitive(.Int)
        case "String": return .primitive(.String)
        case "Float": return .primitive(.Float)
        case "Bool": return .primitive(.Bool)
        default:
            return .complex(str)
//            if String(str.suffix(1)) == "[" {
//                str = String(str.suffix(str.count - 1))
//                str = String(str.prefix(str.count - 1))
//                return .Array(decode(str: str))
//            }
//            else {
//                return .Complex(str)
//            }
        }
    }
}

enum PrimitiveType: String, Codable {
    case String
    case Int
    case Float
    case Bool
}

