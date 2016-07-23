//
//  S2Geometry.swift
//  pgomap
//
//  Created by Luke Sapan on 7/21/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


class S2Point {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}


class S2LatLon {
    let lat: Double
    let lon: Double
    
    init(latDegrees: Double, lonDegrees: Double) {
        lat = latDegrees * M_PI / 180
        lon = lonDegrees * M_PI / 180
    }
    
    func toPoint() -> S2Point {
        let phi = lat
        let theta = lon
        let cosphi = cos(phi)
        return S2Point(x: cos(theta) * cosphi, y: sin(theta) * cosphi, z: sin(phi))
    }
}

class S2CellId {
    // projection types
    var LINEAR_PROJECTION: Int = 0
    var TAN_PROJECTION: Int = 1
    var QUADRATIC_PROJECTION: Int = 2
    
    // current projection used
    var PROJECTION: Int = 2
    
    var FACE_BITS: Int = 3
    var NUM_FACES: Int = 6
    
    var MAX_LEVEL: Int = 30
    var POS_BITS: Int = 2 * 30 + 1
    var MAX_SIZE: Int = 1 << 30
    
    var WRAP_OFFSET: UInt64 = 6 << (2 * (30 + 1))
}
