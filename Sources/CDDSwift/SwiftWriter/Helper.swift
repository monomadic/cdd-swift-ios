//
//  Helper.swift
//  cdd-swift
//
//  Created by Alexei on 04/07/2019.
//

extension String {
    func capitalizingFirstLetter() -> String {
        let first = self.prefix(1).uppercased()
        let other = self.dropFirst()
        return first + other
    }
}
