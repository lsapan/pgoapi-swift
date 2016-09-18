//
//  PGoEncrypt.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-08-06.
//
//

import Foundation


open class PGoEncrypt {
    fileprivate static func getHighByte(_ x: UInt16) -> UInt8 {
        return UInt8(x >> 8)
    }
    
    fileprivate static func getLowByte(_ x: UInt16) -> UInt8 {
        return UInt8(x & 0x00FF)
    }
    
    fileprivate static func rotl8(_ v:UInt8, n:UInt8) -> UInt8 {
        let rotateBits = n % 8
        var t = UInt16(v)
        t = t << UInt16(rotateBits)
        return (getLowByte(t) ^ getHighByte(t))
    }
    
    open static func encrypt(_ input: Array<UInt8>, iv_: Array<UInt8>? = nil) -> Array<UInt8> {
        var iv: Array<UInt8>
        if iv_ != nil {
            iv = iv_!
        } else {
            iv = Data.randomBytes().getUInt8Array()
        }
        
        var buffer = Array<UInt8>(repeating: 0, count: 256)
        let totalsize = input.count + (256 - (input.count % 256)) + 32
        var output = Array<UInt8>(repeating: 0, count: Int(totalsize))

        for j in 0..<8 {
            for i in 0..<32 {
                buffer[32 * j + i] = rotl8(iv[i], n: UInt8(j))
            }
        }
                
        output.replaceSubrange(Range(0..<32), with: iv)
        output.replaceSubrange(Range(32..<(32 + input.count)), with: input)
        output[totalsize - 1] = 1 &+ (255 &- UInt8(input.count % 256))
        
        for offset in stride(from: 32, to: totalsize, by: 256) {
            for i in 0..<256 {
                output[offset + i] ^= buffer[i]
            }
            
            let sliceUInt8 = Array(output[offset..<output.count])
            let slice = UnsafeConverter.bytesAsUInt32Buffer(sliceUInt8)
            let sliceEncrypted = PGoEncryptHelper.encryptUInt32(slice)
            let sliceUInt8Encrypted = UnsafeConverter.UInt32BufferBytes(sliceEncrypted)
            
            buffer = sliceUInt8Encrypted
            output.replaceSubrange(Range(offset..<(offset + sliceUInt8Encrypted.count)), with: sliceUInt8Encrypted)
        }
        return output
    }
}
