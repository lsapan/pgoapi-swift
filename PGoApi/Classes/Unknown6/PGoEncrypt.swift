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
    
    public func encryptUsingLib(input: NSData, iv_: NSData? = nil) -> NSData {
        var iv: NSData? = iv_
        if iv_ == nil {
            iv = randomBytes()
        }
        var outputSize: size_t = 0
        encryptUnknown6(UnsafePointer<UInt8>(input.bytes), input.length,
                        UnsafePointer<UInt8>(iv!.bytes), iv!.length, nil, &outputSize)
        
        let output: NSData = NSMutableData(length: outputSize)!
        encryptUnknown6(UnsafePointer<UInt8>(input.bytes), input.length,
                        UnsafePointer<UInt8>(iv!.bytes), iv!.length,
                        UnsafeMutablePointer<UInt8>(output.bytes), &outputSize)
        
        let usedOutput = outputSize < output.length ? output.subdataWithRange(NSMakeRange(0, outputSize)) : output
        return usedOutput
    }
    
    /*
     
     // Broken functions from swift port
     
     private func rotl8(v: UInt8, n: UInt8) -> UInt8 {
     return ((v << n) & 0xFF) | (v >> (8 - n))
     }
     
     public func encrypt(input: Array<UInt8>, iv: Array<UInt8>) -> Array<UInt8> {
     
     // This function is broken for now, cannot compile any of the sub functions in swift.
     // Gave up and used the c code
     
     var buffer1 = Array<UInt8>(count: 256, repeatedValue: 0)
     let buffer2 = Array<UInt8>(count: 256, repeatedValue: 0)
     
     var roundedsize: UInt32 = 256
     var totalsize: UInt32
     
     let input_size = UInt32(input.count)
     
     roundedsize = input_size - (input_size % 256)
     totalsize = roundedsize + 32
     
     var output = Array<UInt8>(count: Int(totalsize), repeatedValue: 0)
     
     for j in 0..<8 {
     for i in 0..<32 {
     buffer1[32 * j + i] = rotl8(iv[i], n: UInt8(j))
     }
     }
     
     output.replaceRange(Range(0..<32), with: iv)
     output.replaceRange(Range(32..<input.count), with: input)
     
     var outputEncrypted: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer()
     
     if (roundedsize > input_size) {
     let buffer3 = Array<UInt8>(count: Int(roundedsize - input_size), repeatedValue: 0)
     output += buffer3
     }
     output[Int(totalsize - 1)] = 1 &+ 255 &- UInt8(input_size % 256)
     
     for var offset in 32...Int(totalsize) {
     for i in 0..<256 {
     output[offset + i] ^= buffer1[i]
     }
     
     let sliceUInt8 = Array(output[offset..<output.length])
     let slice = UnsafePointer<UInt32>(sliceUInt8).memory
     let sliceEncrypted = encryptUInt32(slice, buffer2UInt32)
     let sliceReturned = UnsafePointer<UInt8>(sliceEncrypted).memory
     
     buffer1 += sliceReturned
     outputEncrypted += sliceReturned
     offset += 256
     }
     return outputEncrypted
     }
     
     */
}
