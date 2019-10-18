
//
//  ProjectInfo.swift
//  CYaml
//
//  Created by Rob Saunders on 7/16/19.
//

import Foundation

struct ProjectInfo: Codable {
	var modificationDate: Date
    var host: String
    var endpoint: String

	func newest(_ left: ProjectInfo, _ right: ProjectInfo) -> ProjectInfo {
		return left.modificationDate.compare(right.modificationDate) == .orderedAscending ? left : right
	}

	static func order(_ left: ProjectInfo, _ right: ProjectInfo) -> (ProjectInfo, ProjectInfo) {
		return left.modificationDate == left.newest(left, right).modificationDate ? (left, right) : (right, left)
	}

	func merge(with otherProject: ProjectInfo) -> ProjectInfo {
		let (_, newest) = ProjectInfo.order(self, otherProject)
		return newest
	}
}
