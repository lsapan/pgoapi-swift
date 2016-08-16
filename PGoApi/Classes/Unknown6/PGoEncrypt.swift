//
//  PGoEncrypt.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-08-06.
//
//

import Foundation


public class PGoEncrypt {
    public init () {
        
    }
    
    public func randomBytes(len: Int? = 32) -> NSData {
        var randomBytes = [UInt8](count: len!, repeatedValue: 0)
        SecRandomCopyBytes(kSecRandomDefault, len!, &randomBytes)
        return NSData(bytes: randomBytes, length: len!)
    }
    
    private func getHighByte(x: UInt16) -> UInt8 {
        return UInt8(x >> 8)
    }
    
    private func getLowByte(x: UInt16) -> UInt8 {
        return UInt8(x & 0x00FF)
    }
    
    private func rotl8(v:UInt8, n:UInt8) -> UInt8 {
        let rotateBits = n % 8
        var t = UInt16(v)
        t = t << UInt16(rotateBits)
        return (getLowByte(t) ^ getHighByte(t))
    }
    
    func unsafeToArray(length: Int, data: UnsafePointer<UInt32>) -> [UInt32] {
        
        let buffer = UnsafeBufferPointer(start: data, count: length)
        return Array(buffer)
    }
    
    func unsafeToArrayUInt8(length: Int, data: UnsafePointer<UInt8>) -> [UInt8] {
        
        let buffer = UnsafeBufferPointer(start: data, count: length)
        return Array(buffer)
    }
     
    public func encrypt(input: Array<UInt8>) -> Array<UInt8> {
     
        var iv = randomBytes().getUInt8Array()
        var buffer1 = Array<UInt8>(count: 256, repeatedValue: 0)
        let buffer2 = Array<UInt8>(count: 256, repeatedValue: 0)

        let totalsize = input.count + (256 - (input.count % 256)) + 32

        var output = Array<UInt8>(count: Int(totalsize), repeatedValue: 0)

        for j in 0..<8 {
            for i in 0..<32 {
                buffer1[32 * j + i] = rotl8(iv[i], n: UInt8(j))
            }
        }
                
        output.replaceRange(Range(0..<32), with: iv)
        output.replaceRange(Range(32..<(32 + input.count)), with: input)
        output[totalsize - 1] = 1 &+ (255 &- UInt8(input.count % 256))
        
        for offset in 32.stride(to: totalsize, by: 256) {
            for i in 0..<256 {
                output[offset + i] ^= buffer1[i]
            }
            
            let sliceUInt8 = Array(output[offset..<output.count])
            let slice = unsafeToArray((sliceUInt8.count/4), data: UnsafePointer<UInt32>(sliceUInt8))
            let sliceEncrypted = PGoEncryptHelper().encryptUInt32(slice)
            let sliceUInt8Encrypted = unsafeToArrayUInt8((sliceEncrypted.count * 4), data: UnsafePointer<UInt8>(sliceEncrypted))
            
            buffer1 = sliceUInt8Encrypted
            output.replaceRange(Range(offset..<(offset + sliceUInt8Encrypted.count)), with: sliceUInt8Encrypted)
        }
        return output
    }
}
