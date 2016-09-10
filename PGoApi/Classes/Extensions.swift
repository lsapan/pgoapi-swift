//
//  Extensions.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


internal extension NSRange {
    internal func rangeForString(str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        return str.startIndex.advancedBy(location) ..< str.startIndex.advancedBy(location + length)
    }
}

internal extension NSData {
    internal func getUInt8Array() -> Array<UInt8> {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(self.bytes), count: self.length))
    }
    internal func getUInt32Array() -> Array<UInt32> {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt32>(self.bytes), count: self.length))
    }
    internal var getHexString: String {
        var bytes = [UInt8](count: length, repeatedValue: 0)
        getBytes(&bytes, length: length)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        return String(hexString)
    }
    internal static func randomBytes(len: Int? = 32) -> NSData {
        var randomBytes = [UInt8](count: len!, repeatedValue: 0)
        SecRandomCopyBytes(kSecRandomDefault, len!, &randomBytes)
        return NSData(bytes: randomBytes, length: len!)
    }
}

internal extension Float {
    internal static var random:Float {
        get {
            return Float(arc4random()) / 0xFFFFFFFF
        }
    }
    internal static func random(min min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
}


internal extension UInt64 {
    internal static func random(min: UInt64, max: UInt64) -> UInt64 {
        return UInt64(Double(max - min) * drand48() + Double(min))
    }
    internal func getInt64() -> Int64{
        let bytes = UnsafeConverter.bytes(self)
        let value = bytes.withUnsafeBufferPointer({
            UnsafePointer<Int64>($0.baseAddress).memory
        })
        return value
    }
}

internal extension Int {
    internal func strideByInt(to upper: Int, by step: Int = 1, @noescape closure: (k: Int64) -> Void) {
        for k in self.stride(through: upper, by: step) {
            closure(k: Int64(k))
        }
    }
}

internal extension Int64 {
    internal func getUInt64() -> UInt64{
        let bytes = UnsafeConverter.bytes(self)
        let value = bytes.withUnsafeBufferPointer({
            UnsafePointer<UInt64>($0.baseAddress).memory
        })
        return value
    }
}

internal class UnsafeConverter {
    internal static func bytes<T>(value_: T) -> [UInt8] {
        var value = value_
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: 8))
        }
    }
}