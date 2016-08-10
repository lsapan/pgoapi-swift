//
//  xxhash.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-08-06.
//
//

import Foundation


public class xxhash {
    private var _state: xxh32_state
    private let PRIME32_1: UInt32 = 2654435761
    private let PRIME32_2: UInt32 = 2246822519
    private let PRIME32_3: UInt32 = 3266489917
    private let PRIME32_4: UInt32 = 668265263
    private let PRIME32_5: UInt32 = 374761393
    
    private let PRIME64_1: UInt64 = 11400714785074694791
    private let PRIME64_2: UInt64 = 14029467366897019727
    private let PRIME64_3: UInt64 = 1609587929392839161
    private let PRIME64_4: UInt64 = 9650029242287828579
    private let PRIME64_5: UInt64 = 2870177450012600261
    
    private func buildUInt32(bytes: Array<UInt8>) -> UInt32 {
        let data = NSData(bytes: bytes, length: 4)
        var result: UInt32 = 0
        data.getBytes(&result, length: 32)
        return result
    }
    
    private func buildUInt64(bytes: Array<UInt8>) -> UInt64 {
        let data = NSData(bytes: bytes, length: 8)
        var result: UInt64 = 0
        data.getBytes(&result, length: 64)
        return result
    }
    
    public init(seed: UInt32) {
        _state = xxh32_state(total_len: 0, seed: seed, v1: seed &+ PRIME32_1 &+ PRIME32_2, v2: seed &+ PRIME32_2, v3: seed &+ 0, v4: seed &- PRIME32_1, memsize: 0, memory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
    }
    
    public func xxh64(seed: UInt64, input: Array<UInt8>) -> UInt64 {
        var h64: UInt64 = 0
        let len = input.count
        var p: Int64 = 0
        let bEnd = Int64(len)
        
        if len >= 32 {
            var v1 = seed &+ PRIME64_1 &+ PRIME64_2
            var v2 = seed &+ PRIME64_2
            var v3 = seed &+ 0
            var v4 = seed &- PRIME64_1
            
            while p <= bEnd - 32 {
                v1 = v1 &+ buildUInt64(Array(input[Int(p)..<input.count])) &* PRIME64_2
                v1 = rotl64(v1, count: 31) &* PRIME64_1
                p += 8
                
                v2 = v2 &+ buildUInt64(Array(input[Int(p)..<input.count])) &* PRIME64_2
                v2 = rotl64(v2, count: 31) &* PRIME64_1
                p += 8
                
                
                v3 = v3 &+ buildUInt64(Array(input[Int(p)..<input.count])) &* PRIME64_2
                v3 = rotl64(v3, count: 31) &* PRIME64_1
                p += 8
                
                
                v4 = v4 &+ buildUInt64(Array(input[Int(p)..<input.count])) &* PRIME64_2
                v4 = rotl64(v4, count: 31) &* PRIME64_1
                p += 8
            }
            
            h64 = rotl64(v1, count: 1) &+ rotl64(v2, count: 7) &+ rotl64(v3, count: 12) &+ rotl64(v4, count: 18)
            
            let round1 = rotl64(v1 &* PRIME64_2, count: 31) &* PRIME64_1
            h64 ^= round1
            h64 = h64 &* PRIME64_1 &+ PRIME64_4
            
            let round2 = rotl64(v2 &* PRIME64_2, count: 31) &* PRIME64_1
            h64 ^= round2
            h64 = h64 &* PRIME64_1 &+ PRIME64_4
            
            let round3 = rotl64(v3 &* PRIME64_2, count: 31) &* PRIME64_1
            h64 ^= round3
            h64 = h64 &* PRIME64_1 &+ PRIME64_4
            
            let round4 = rotl64(v4 &* PRIME64_2, count: 31) &* PRIME64_1
            h64 ^= round4
            h64 = h64 &* PRIME64_1 &+ PRIME64_4
        } else {
            h64 = seed &+ PRIME64_5
        }
        
        h64 = h64 &+ UInt64(len)
        
        while p <= (bEnd - 8) {
            let round1 = rotl64(buildUInt64(Array(input[Int(p)..<input.count])) &* PRIME64_2, count: 31) &* PRIME64_1
            h64 ^= round1
            h64 = rotl64(h64, count: 27) &* PRIME64_1 &+ PRIME64_4
            p += 8
        }
        
        while p <= (bEnd - 4) {
            
            h64 ^= UInt64(buildUInt32(Array(input[Int(p)..<Int(len)]))) &* PRIME64_1
            h64 = rotl64(h64, count: 23) &* PRIME64_2 &+ PRIME64_3
            p += 4
        }
        
        while p < bEnd {
            h64 ^= UInt64(input[Int(p)]) &* PRIME64_5
            h64 = rotl64(h64, count: 11) &* PRIME64_1
            p += 1
        }
        
        h64 ^= h64 >> 33
        h64 = h64 &* PRIME64_2
        h64 ^= h64 >> 29
        h64 = h64 &* PRIME64_3
        h64 ^= h64 >> 32
        
        return h64
    }
    
    public func update(input: [UInt8]) -> Bool {
        let len = Int32(input.count)
        var index: Int32 = 0
        _state.total_len = _state.total_len &+ UInt16(len)
        
        if (_state.memsize &+ len) < 16 {
            _state.memory = Array(input[0..<Int(len)])
            _state.memsize = _state.memsize &+ len
            return true
        }
        
        if _state.memsize > 0 {
            _state.memory = Array(input[Int(_state.memsize)..<Int(16 - _state.memsize)])
            _state.v1 = h32sub(_state.v1, buf: _state.memory, index: index)
            index = index + 4
            _state.v2 = h32sub(_state.v2, buf: _state.memory, index: index)
            index = index + 4
            _state.v3 = h32sub(_state.v3, buf: _state.memory, index: index)
            index = index + 4
            _state.v4 = h32sub(_state.v4, buf: _state.memory, index: index)
            index = index + 4
            index = 0
            _state.memsize = 0
        }
        
        if index <= (len - 16) {
            let limit: Int32 = len - 16
            var v1: UInt32 = _state.v1
            var v2: UInt32 = _state.v2
            var v3: UInt32 = _state.v3
            var v4: UInt32 = _state.v4
            
            while index <= limit {
                v1 = h32sub(v1, buf: input, index: index)
                index = index + 4
                v2 = h32sub(v2, buf: input, index: index)
                index = index + 4
                v3 = h32sub(v3, buf: input, index: index)
                index = index + 4
                v4 = h32sub(v4, buf: input, index: index)
                index = index + 4
            }
            
            _state.v1 = v1
            _state.v2 = v2
            _state.v3 = v3
            _state.v4 = v4
        }
        
        if index < len {
            _state.memory = Array(input[Int(index)..<Int(len)])
            _state.memsize = len - index
        }
        return true
    }
    
    public func digest() -> UInt32 {
        var h32: UInt32
        var index: Int32 = 0
        
        if _state.total_len >= 16 {
            h32 = rotl32(_state.v1, count: 1) &+ rotl32(_state.v2, count: 7) &+ rotl32(_state.v3, count: 12) &+ rotl32(_state.v4, count: 18)
        } else {
            h32 = _state.seed &+ PRIME32_5
        }
        
        h32 = h32 &+ UInt32(_state.total_len)
        
        while index <= (_state.memsize - 4) {
            h32 = h32 &+ buildUInt32(Array(_state.memory[Int(index)..<_state.memory.count])) &* PRIME32_3
            h32 = rotl32(h32, count: 17) &* PRIME32_4
            index += 4
        }
        
        while index < _state.memsize {
            h32 = h32 &+ UInt32(_state.memory[Int(index)]) &* PRIME32_5
            h32 = rotl32(h32, count: 11) &* PRIME32_1
            index += 1
        }
                
        h32 ^= h32 >> 15
        h32 = h32 &* PRIME32_2
        h32 ^= h32 >> 13
        h32 = h32 &* PRIME32_3
        h32 ^= h32 >> 16

        return h32
    }
    
    private func h32sub(value_: UInt32, buf: [UInt8], index: Int32) -> UInt32 {
        var value = value_
        let read_value: UInt32 = buildUInt32(Array(buf[Int(index)..<buf.count]))
        value = value &+ read_value &* PRIME32_2
        value = rotl32(value, count: 13)
        value = value &* PRIME32_1
        return value
    }
    
    private func rotl32(x: UInt32, count: UInt32) -> UInt32 {
        return x << count | x >> (32 - count)
    }
    
    private func h64sub(value_: UInt64, buf: [UInt8], index: Int64) -> UInt64 {
        var value = value_
        let read_value: UInt64 = buildUInt64(Array(buf[Int(index)..<buf.count]))
        value = value &+ read_value &* PRIME64_2
        value = rotl64(value, count: 13)
        value = value &* PRIME64_1
        return value
    }
    
    private func rotl64(x: UInt64, count: UInt64) -> UInt64 {
        return x << count | x >> (64 - count)
    }
    
    private struct xxh32_state {
        var total_len: UInt16 = 0
         var seed: UInt32 = 0
         var v1: UInt32 = 0
         var v2: UInt32 = 0
         var v3: UInt32 = 0
         var v4: UInt32 = 0
         var memsize: Int32 = 0
         var memory: [UInt8]
    }
}

