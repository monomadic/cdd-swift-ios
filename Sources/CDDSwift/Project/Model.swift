//
//  Model.swift
//  CYaml
//
//  Created by Rob Saunders on 7/16/19.
//

import Foundation

struct Model: ProjectObject, Codable {
	var name: String
	var vars: [Variable]
}
