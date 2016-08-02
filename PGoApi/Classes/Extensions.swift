//
//  Extensions.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation

extension NSRange {
    func rangeForString(str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        return str.startIndex.advancedBy(location) ..< str.startIndex.advancedBy(location + length)
    }
}
