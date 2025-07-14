//
//  Item.swift
//  MACPDFCompressor
//
//  Created by Andrew Tanny Liem on 14/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
