//
//  pcrypt.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-10-06.
//
//

import Foundation


open class pcrypt {
    fileprivate static func genRand(tmp: inout UInt32) -> UInt8 {
        tmp = tmp &* 0x41c64e6d &+ 12345
        let result = (tmp >> 16) & 0xff
        return UnsafeConverter.bytes(result)[0]
    }
    
    fileprivate static func makeIntegrityByte(byt: UInt8) -> UInt8 {
        let tmp = (byt ^ 0x0c) & byt
        return ((~tmp & 0x67) | (tmp & 0x98)) ^ 0x6f | (tmp & 0x08)
    }
    
    open static func encrypt(input: Array<UInt8>, iv: UInt32) -> [UInt8] {
        var ms = iv
        let len = input.count
        let totalSize = len + (256 - (len % 256)) + 5
        var output8 = Array<UInt8>(repeating: 0, count: totalSize + 3)
        var output32 = Array<UInt32>(repeating: 0, count: (totalSize + 3)/4)
        
        // Write out seed
        let msBytes = UnsafeConverter.bytes(iv.bigEndian)
        output8.replaceSubrange(Range(0..<4), with: msBytes)
        output8.replaceSubrange(Range(4..<len), with: input)
        output8[totalSize - 2] = UInt8(256 - (len % 256))
        
        // Generate cipher and integrity byte
        var cipher8 = Array<UInt8>(repeating: 0, count: 256)
        for i in 0..<256 {
            cipher8[i] = genRand(tmp: &ms)
        }
        
        var cipher32 = UnsafeConverter.bytesAsUInt32Buffer(cipher8)
        output8[totalSize - 1] = makeIntegrityByte(byt: genRand(tmp: &ms))
        output32.replaceSubrange(Range(0..<(totalSize/4)), with: UnsafeConverter.bytesAsUInt32Buffer(output8))
        
        // Encrypt in chunks of 256 bytes
        for offset in stride(from: 4, to: totalSize - 1, by: 256) {
            for i in 0..<64 {
                output32[offset / 4 + i] ^= cipher32[i]
            }
            let output32Chunk = Array(output32[offset/4..<(offset + 256)/4])
            let output32ChunkBytes = UnsafeConverter.UInt32BufferBytes(output32Chunk)
            output8.replaceSubrange(Range(offset..<(offset + 256)), with: output32ChunkBytes)
            
            pcrypt.shuffle(&output8, offset: offset)

            let output8Chunk = Array(output8[offset..<(offset + 256)])
            cipher32.replaceSubrange(Range(0..<(256/4)), with: UnsafeConverter.bytesAsUInt32Buffer(output8Chunk))
        }
        return Array(output8[0..<totalSize])
    }
}
