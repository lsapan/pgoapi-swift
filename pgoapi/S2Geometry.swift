//
//  S2Geometry.swift
//  pgomap
//
//  Created by Luke Sapan on 7/21/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


enum S2Projection {
    case Linear
    case Tan
    case Quadratic
}

enum S2Constants {
    static let maxLevel = 30
    static let posBits = 2 * (S2Constants.maxLevel + 1)
    static let maxSize = 1 << S2Constants.maxLevel
    static let swapMask = 0x01
    static let invertMask = 0x02
    static let lookupBits = 4
}

var lookupPos: [Int] = []

struct S2FaceUv {
    let face: Int
    let u: Double
    let v: Double
}

struct S2Uv {
    let u: Double
    let v: Double
}

class S2Point {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func pointAbs() -> [Double] {
        return [abs(x), abs(y), abs(z)]
    }
    
    func largestAbsComponent() -> Int {
        let temp = pointAbs()
        if temp[0] > temp[1] {
            if temp[0] > temp[2] {
                return 0
            } else {
                return 2
            }
        } else {
            if temp[1] > temp[2] {
                return 1
            } else {
                return 2
            }
        }
    }
    
    func dotProd(o: S2Point) -> Double {
        return x * o.x + y * o.y + z * o.z
    }
    
    static func faceUvToXyz(face: Int, u: Double, v: Double) -> S2Point {
        let uDouble = Double(u)
        let vDouble = Double(v)
        if face == 0 {
            return S2Point(x: 1, y: uDouble, z: vDouble)
        } else if face == 1 {
            return S2Point(x: -uDouble, y: 1, z: vDouble)
        } else if face == 2 {
            return S2Point(x: -uDouble, y: -vDouble, z: 1)
        } else if face == 3 {
            return S2Point(x: -1, y: -vDouble, z: -uDouble)
        } else if face == 4 {
            return S2Point(x: vDouble, y: -1, z: -uDouble)
        } else {
            return S2Point(x: vDouble, y: uDouble, z: -1)
        }
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
    var id: Double
    
    init(id: Double) {
        self.id = id
    }
    
    convenience init(p: S2Point) {
        let faceUv = S2CellId.xyzToFaceUv(p)
        let i = S2CellId.stToIj(S2CellId.uvToSt(.Quadratic, u: faceUv.u))
        let j = S2CellId.stToIj(S2CellId.uvToSt(.Quadratic, u: faceUv.v))
        self.init(face: faceUv.face, i: i, j: j)
    }
    
    convenience init(face: Int, i: Int, j: Int) {
        var  n = face << (S2Constants.posBits - 1)
        var bits = face & S2Constants.swapMask
        
        for k in 7.stride(to: -1, by: -1) {
            let mask = (1 << S2Constants.lookupBits) - 1
            bits += (((i >> (k * S2Constants.lookupBits)) & mask) << (S2Constants.lookupBits + 2))
            bits += (((j >> (k * S2Constants.lookupBits)) & mask) << 2)
            bits = lookupPos[bits]
            n |= (bits >> 2) << (k * 2 * S2Constants.lookupBits)
            bits &= (S2Constants.swapMask | S2Constants.invertMask)
        }
        
        self.init(id: (Double(n) * 2) + 1)
    }
    
    static func xyzToFaceUv(p: S2Point) -> S2FaceUv {
        var face = p.largestAbsComponent()
        var pFace: Double
        if face == 0 {
            pFace = p.x
        } else if face == 1 {
            pFace = p.y
        } else {
            pFace = p.z
        }
        if pFace < 0 {
            face += 3
        }
        let uv = validFaceXyzToUv(face, p: p)
        return S2FaceUv(face: face, u: uv.u, v: uv.v)
    }
 
    static func uvToSt(projection: S2Projection, u: Double) -> Double {
        if projection == .Linear {
            return 0.5 * (u + 1)
        } else if projection == .Tan {
            return (2 * (1.0 / M_PI)) * (atan(u) * M_PI / 4.0)
        } else {
            if u >= 0 {
                return 0.5 * sqrt(1 + 3 * u)
            } else {
                return 1 - 0.5 * sqrt(1 - 3 * u)
            }
        }
    }
 
    static func stToIj(s: Double) -> Int {
        return max(0, min(S2Constants.maxSize - 1, Int(floor(Double(S2Constants.maxSize) * s))))
    }

    static func validFaceXyzToUv(face: Int, p: S2Point) -> S2Uv {
        assert(p.dotProd(S2Point.faceUvToXyz(face, u: 0, v: 0)) > 0)
        if face == 0 {
            return S2Uv(u: p.y / p.x, v: p.z / p.x)
        } else if face == 1 {
            return S2Uv(u: -p.x / p.y, v: p.z / p.y)
        } else if face == 2 {
            return S2Uv(u: -p.x / p.z, v: -p.y / p.z)
        } else if face == 3 {
            return S2Uv(u: p.z / p.x, v: p.y / p.x)
        } else if face == 4 {
            return S2Uv(u: p.z / p.y, v: -p.x / p.y)
        } else {
            return S2Uv(u: -p.y / p.z, v: -p.x / p.z)
        }
    }
}
