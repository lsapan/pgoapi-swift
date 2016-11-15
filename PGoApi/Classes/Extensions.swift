//
//  Extensions.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire


internal struct BinaryEncoding: ParameterEncoding {
    private let data: Data
    
    internal init(data: Data) {
        self.data = data
    }
    
    internal func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        let mutableRequest = urlRequest as! NSMutableURLRequest
        mutableRequest.httpBody = data
        return mutableRequest as URLRequest
    }
}

internal extension NSRange {
    internal func rangeForString(_ str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        return str.characters.index(str.startIndex, offsetBy: location) ..< str.characters.index(str.startIndex, offsetBy: location + length)
    }
}

internal extension Data {
    internal func getUInt8Array() -> Array<UInt8> {
        var byteArray = [UInt8]()
        self.withUnsafeBytes {(bytes: UnsafePointer<UInt8>)->Void in
            let buffer = UnsafeBufferPointer(start: bytes, count: count);
            byteArray = Array(buffer)
        }
        return byteArray
    }
    internal var getHexString: String {
        var bytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytes, count: count)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        return String(hexString)
    }
    internal static func randomBytes(_ len: Int? = 32) -> Data {
        var randomBytes = [UInt8](repeating: 0, count: len!)
        _ = SecRandomCopyBytes(kSecRandomDefault, len!, &randomBytes)
        return Data(bytes: UnsafePointer<UInt8>(randomBytes), count: len!)
    }
}

internal extension Float {
    internal static var random:Float {
        get {
            return Float(arc4random()) / 0xFFFFFFFF
        }
    }
    internal static func random(min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
}


internal extension UInt64 {
    internal static func random(_ min: UInt64, max: UInt64) -> UInt64 {
        return UInt64(Double(max - min) * drand48() + Double(min))
    }
    internal func getInt64() -> Int64 {
        let bytes = UnsafeConverter.bytes(self)
        let value = UnsafePointer(bytes).withMemoryRebound(to: Int64.self, capacity: 1) {
            $0.pointee
        }
        return value
    }
}

internal extension UInt32 {
    internal func getInt32() -> Int32 {
        let bytes = UnsafeConverter.bytes(self)
        let value = UnsafePointer(bytes).withMemoryRebound(to: Int32.self, capacity: 1) {
            $0.pointee
        }
        return value
    }
}

internal extension Int32 {
    internal func getUInt32() -> UInt32 {
        let bytes = UnsafeConverter.bytes(self)
        let value = UnsafePointer(bytes).withMemoryRebound(to: UInt32.self, capacity: 1) {
            $0.pointee
        }
        return value
    }
}

internal extension Int64 {
    internal func getUInt64() -> UInt64 {
        let bytes = UnsafeConverter.bytes(self)
        let value = UnsafePointer(bytes).withMemoryRebound(to: UInt64.self, capacity: 1) {
            $0.pointee
        }
        return value
    }
}

internal class UnsafeConverter {
    internal static func bytes<T>(_ value: T) -> [UInt8] {
        var mv : T = value
        let s : Int = MemoryLayout<T>.size
        return withUnsafePointer(to: &mv) {
            $0.withMemoryRebound(to: UInt8.self, capacity: s) {
                Array(UnsafeBufferPointer(start: $0, count: s))
            }
        }
    }
    internal static func UInt32BufferBytes(_ value: [UInt32]) -> [UInt8] {
        let numBytes = value.count
        guard (numBytes * 4) % 4 == 0 else { return [] }
        
        var arr = [UInt8]()
        for i in (0..<numBytes) {
            arr.append(contentsOf: bytes(value[i]).reversed())
        }
        return arr
    }
    internal static func bytesAsUInt32Buffer(_ byteArr: [UInt8]) -> [UInt32] {
        let numBytes = byteArr.count
        var byteArrSlice = byteArr[0..<numBytes]
        guard numBytes % 4 == 0 else { return [] }
        
        var arr = [UInt32](repeating: 0, count: numBytes/4)
        for i in (0..<numBytes/4).reversed() {
            arr[i] = UInt32(byteArrSlice.removeLast())
            arr[i] += UInt32(byteArrSlice.removeLast()) << 8
            arr[i] += UInt32(byteArrSlice.removeLast()) << 16
            arr[i] += UInt32(byteArrSlice.removeLast()) << 24
        }
        return arr
    }
    internal static func bytesAsUInt32(_ value_: [UInt8]) -> UInt32 {
        var value: [UInt8] = value_
        if value.count > 4 {
            value = Array(value[0..<4])
        }
        if value.count < 4 {
            let bytesToAdd: [UInt8] = [UInt8](repeating: 0, count: 4 - value.count)
            value.append(contentsOf: bytesToAdd)
        }
        var newUInt32: UInt32 = 0
        for i in 0..<value.count {
            newUInt32 += UInt32(value[i]) << UInt32(8 * i)
        }
        return newUInt32
    }
    internal static func bytesAsUInt64(_ value_: [UInt8]) -> UInt64 {
        var value: [UInt8] = value_
        if value.count > 8 {
            value = Array(value[0..<8])
        }
        if value.count < 8 {
            let bytesToAdd: [UInt8] = [UInt8](repeating: 0, count: 8 - value.count)
            value.append(contentsOf: bytesToAdd)
        }
        var newUInt64: UInt64 = 0
        for i in 0..<value.count {
            newUInt64 += UInt64(value[i]) << UInt64(8 * i)
        }
        return newUInt64
    }

}
