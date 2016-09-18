//
//  xxhash.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-08-06.
//
//

import Foundation


open class xxhash {
    fileprivate static let PRIME32_1: UInt32 = 2654435761
    fileprivate static let PRIME32_2: UInt32 = 2246822519
    fileprivate static let PRIME32_3: UInt32 = 3266489917
    fileprivate static let PRIME32_4: UInt32 = 668265263
    fileprivate static let PRIME32_5: UInt32 = 374761393
    
    fileprivate static let PRIME64_1: UInt64 = 11400714785074694791
    fileprivate static let PRIME64_2: UInt64 = 14029467366897019727
    fileprivate static let PRIME64_3: UInt64 = 1609587929392839161
    fileprivate static let PRIME64_4: UInt64 = 9650029242287828579
    fileprivate static let PRIME64_5: UInt64 = 2870177450012600261
    
    open static func xxh32(_ seed: UInt32, input: Array<UInt8>) -> UInt32 {
        var h32: UInt32
        var index: Int32 = 0
        let len: Int32 = Int32(input.count)
        
        if len >= 16 {
            let limit = len - 16
            var v1: UInt32 = seed &+ xxhash.PRIME32_1 &+ xxhash.PRIME32_2
            var v2: UInt32 = seed &+ xxhash.PRIME32_2
            var v3: UInt32 = seed &+ 0
            var v4: UInt32 = seed &- xxhash.PRIME32_1
            
            while index <= limit {
                v1 = h32sub(v1, buf: input, index: index)
                index += 4
                v2 = h32sub(v2, buf: input, index: index)
                index += 4
                v3 = h32sub(v3, buf: input, index: index)
                index += 4
                v4 = h32sub(v4, buf: input, index: index)
                index += 4
            }

            h32 = xxhash.rotl32(v1, count: 1) &+ xxhash.rotl32(v2, count: 7) &+ xxhash.rotl32(v3, count: 12) &+ xxhash.rotl32(v4, count: 18)
        } else {
            h32 = seed &+ xxhash.PRIME32_5
        }

        h32 = h32 &+ UInt32(len)

        while index <= (len - 4) {
            h32 = h32 &+ UnsafeConverter.bytesAsUInt32(Array(input[Int(index)..<input.count])) &* xxhash.PRIME32_3
            h32 = xxhash.rotl32(h32, count: 17) &* xxhash.PRIME32_4
            index += 4
        }
        
        while index<len {
            h32 = h32 &+ UInt32(input[Int(index)]) &* xxhash.PRIME32_5
            h32 = xxhash.rotl32(h32, count: 11) &* xxhash.PRIME32_1
            index += 1
        }
        
        h32 ^= h32 >> 15
        h32 = h32 &* xxhash.PRIME32_2
        h32 ^= h32 >> 13
        h32 = h32 &* xxhash.PRIME32_3
        h32 ^= h32 >> 16
        
        return h32
    }
    
    open static func xxh64(_ seed: UInt64, input: Array<UInt8>) -> UInt64 {
        var h64: UInt64 = 0
        let len = input.count
        var p: Int64 = 0
        let bEnd = Int64(len)
        
        if len >= 32 {
            var v1 = seed &+ xxhash.PRIME64_1 &+ xxhash.PRIME64_2
            var v2 = seed &+ xxhash.PRIME64_2
            var v3 = seed &+ 0
            var v4 = seed &- xxhash.PRIME64_1
            
            while p <= bEnd - 32 {
                v1 = v1 &+ UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<input.count])) &* xxhash.PRIME64_2
                v1 = xxhash.rotl64(v1, count: 31) &* xxhash.PRIME64_1
                p += 8
                
                v2 = v2 &+ UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<input.count])) &* xxhash.PRIME64_2
                v2 = xxhash.rotl64(v2, count: 31) &* xxhash.PRIME64_1
                p += 8
                
                
                v3 = v3 &+ UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<input.count])) &* xxhash.PRIME64_2
                v3 = xxhash.rotl64(v3, count: 31) &* xxhash.PRIME64_1
                p += 8
                
                
                v4 = v4 &+ UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<input.count])) &* xxhash.PRIME64_2
                v4 = xxhash.rotl64(v4, count: 31) &* xxhash.PRIME64_1
                p += 8
            }
            
            h64 = xxhash.rotl64(v1, count: 1) &+ xxhash.rotl64(v2, count: 7) &+ xxhash.rotl64(v3, count: 12) &+ xxhash.rotl64(v4, count: 18)
            
            let round1 = xxhash.rotl64(v1 &* xxhash.PRIME64_2, count: 31) &* xxhash.PRIME64_1
            h64 ^= round1
            h64 = h64 &* xxhash.PRIME64_1 &+ xxhash.PRIME64_4
            
            let round2 = xxhash.rotl64(v2 &* xxhash.PRIME64_2, count: 31) &* xxhash.PRIME64_1
            h64 ^= round2
            h64 = h64 &* xxhash.PRIME64_1 &+ xxhash.PRIME64_4
            
            let round3 = xxhash.rotl64(v3 &* xxhash.PRIME64_2, count: 31) &* xxhash.PRIME64_1
            h64 ^= round3
            h64 = h64 &* xxhash.PRIME64_1 &+ xxhash.PRIME64_4
            
            let round4 = xxhash.rotl64(v4 &* xxhash.PRIME64_2, count: 31) &* xxhash.PRIME64_1
            h64 ^= round4
            h64 = h64 &* xxhash.PRIME64_1 &+ xxhash.PRIME64_4
        } else {
            h64 = seed &+ xxhash.PRIME64_5
        }
        
        h64 = h64 &+ UInt64(len)
        
        while p <= (bEnd - 8) {
            let round1 = xxhash.rotl64(UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<input.count])) &* xxhash.PRIME64_2, count: 31) &* xxhash.PRIME64_1
            h64 ^= round1
            h64 = xxhash.rotl64(h64, count: 27) &* xxhash.PRIME64_1 &+ xxhash.PRIME64_4
            p += 8
        }
        
        while p <= (bEnd - 4) {
            h64 ^= UnsafeConverter.bytesAsUInt64(Array(input[Int(p)..<Int(len)])) &* xxhash.PRIME64_1
            h64 = xxhash.rotl64(h64, count: 23) &* xxhash.PRIME64_2 &+ xxhash.PRIME64_3
            p += 4
        }
        
        while p < bEnd {
            h64 ^= UInt64(input[Int(p)]) &* xxhash.PRIME64_5
            h64 = xxhash.rotl64(h64, count: 11) &* xxhash.PRIME64_1
            p += 1
        }
        
        h64 ^= h64 >> 33
        h64 = h64 &* xxhash.PRIME64_2
        h64 ^= h64 >> 29
        h64 = h64 &* xxhash.PRIME64_3
        h64 ^= h64 >> 32
        
        return h64
    }
    
    fileprivate static func h32sub(_ value_: UInt32, buf: [UInt8], index: Int32) -> UInt32 {
        var value = value_
        let buffer = Array(buf[Int(index)..<buf.count])
        let read_value: UInt32 = UnsafeConverter.bytesAsUInt32(buffer)
        value = value &+ read_value &* xxhash.PRIME32_2
        value = xxhash.rotl32(value, count: 13)
        value = value &* xxhash.PRIME32_1
        return value
    }
    
    fileprivate static func rotl32(_ x: UInt32, count: UInt32) -> UInt32 {
        return x << count | x >> (32 - count)
    }
    
    fileprivate static func h64sub(_ value_: UInt64, buf: [UInt8], index: Int64) -> UInt64 {
        var value = value_
        let buffer = Array(buf[Int(index)..<buf.count])
        let read_value: UInt64 = UnsafeConverter.bytesAsUInt64(buffer)
        value = value &+ read_value &* xxhash.PRIME64_2
        value = xxhash.rotl64(value, count: 13)
        value = value &* xxhash.PRIME64_1
        return value
    }
    
    fileprivate static func rotl64(_ x: UInt64, count: UInt64) -> UInt64 {
        return x << count | x >> (64 - count)
    }
}
