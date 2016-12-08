//
//  niahash.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-11-12.
//
//

import Foundation


public class UInt128 {
    public var high: UInt64 = 0
    public var low: UInt64 = 0
    
    private static func HI(n: UInt64) -> UInt64 {
        return n >> 32
    }
    
    private static func LO(n: UInt64) -> UInt64 {
        return n & 0xffffffff
    }
    
    public init (upperBits: UInt64? = 0, lowerBits: UInt64? = 0) {
        self.high = upperBits!
        self.low = lowerBits!
    }
    
    public static func add128(left: UInt128, right: UInt128) -> UInt128 {
        let sum = UInt128(upperBits: left.high &+ right.high, lowerBits: left.low &+ right.low)
        if (sum.low < right.low) {
            sum.high = sum.high &+ 1
        }
        return sum
    }
    
    public static func cmp128(left: UInt128, right: UInt128) -> Int {
        if (left.high == right.high) {
            if (left.low == right.low) {
                return 0
            }
                return left.low < right.low ? -1 : 1
            }
        return left.high < right.high ? -1 : 1
    }
        
    public static func and128(left: UInt128, right: UInt128) -> UInt128 {
        return UInt128(upperBits: left.high & right.high, lowerBits: left.low & left.low)
    }
    
    public static func mul64(lhs: UInt64, rhs: UInt64) -> UInt128 {
        var left = lhs
        var right = rhs
        let u1 = LO(n: left)
        let v1 = LO(n: right)
        var t = u1 &* v1
        let w3 = LO(n: t)
        var k = HI(n: t)
        
        left = HI(n: left)
        t = (left &* v1) &+ k
        k = LO(n: t)
        let w1 = HI(n: t)
        
        right = HI(n: right)
        t = (u1 &* right) &+ k
        k = HI(n: t)
        
        return UInt128(upperBits: (left &* right) &+ w1 &+ k, lowerBits: (t << 32) &+ w3)
    }
}

open class niahash {
    /* IOS 1.15.0 */
    private static let magic_table: [UInt64] = [0x2dd7caaefcf073eb, 0xa9209937349cfe9c,
                                        0xb84bfc934b0e60ef, 0xff709c157b26e477,
                                        0x3936fd8735455112, 0xca141bf22338d331,
                                        0xdd40e749cb64fd02, 0x5e268f564b0deb26,
                                        0x658239596bdea9ec, 0x31cedf33ac38c624,
                                        0x12f56816481b0cfd, 0x94e9de155f40f095,
                                        0x5089c907844c6325, 0xdf887e97d73c50e3,
                                        0xae8870787ce3c11d, 0xa6767d18c58d2117]
    private static let ROUND_MAGIC = UInt128(upperBits: 0xe3f0d44988bcdfab, lowerBits: 0x081570afdd535ec3)
    private static let FINAL_MAGIC0: UInt64 = 0xce7c4801d683e824
    private static let FINAL_MAGIC1: UInt64 = 0x6823775b1daad522
    private static let HASH_SEED = PGoVersion.HASH_SEED
    
    private static func HI(n: UInt64) -> UInt64 {
        return n >> 32
    }
    
    private static func LO(n: UInt64) -> UInt64 {
        return n & 0xffffffff
    }
    
    public static func hash32(buffer: [UInt8]) -> UInt32 {
        return hash32Salt(buffer: buffer, salt: HASH_SEED)
    }
    
    public static func hash32Salt(buffer: [UInt8], salt: UInt32) -> UInt32 {
        var saltedBuffer = UnsafeConverter.bytes(salt.bigEndian)
        saltedBuffer += buffer

        let result = hash(bytes: saltedBuffer)
        let resultSeed = (result & 0xFFFFFFFF) ^ (result >> 32)
        return UInt32(resultSeed)
    }
    
    public static func hash64(buffer: [UInt8]) -> UInt64 {
        return hash64Salt(buffer: buffer, salt: HASH_SEED)
    }
    
    public static func hash64Salt(buffer: [UInt8], salt: UInt32) -> UInt64 {
        var saltedBuffer = UnsafeConverter.bytes(salt.bigEndian)
        saltedBuffer += buffer
        return hash(bytes: saltedBuffer)
    }
    
    public static func hash64Salt64(buffer: [UInt8], salt: UInt64) -> UInt64 {
        var saltedBuffer = UnsafeConverter.bytes(salt.bigEndian)
        saltedBuffer += buffer
        return hash(bytes: saltedBuffer)
    }
    
    public static func hash(bytes: [UInt8]) -> UInt64 {
        var input = bytes
        let len = input.count
        var numChunks = len / 128
        
        // copy tail, pad with zeroes
        var tail = Array<UInt8>(repeating: 0, count: 128)
        let tailSize = len % 128
        let padZeros = Array<UInt8>(repeating: 0, count: 128 - tailSize)
        input.append(contentsOf: padZeros)
        
        tail.replaceSubrange(Range(0..<tailSize), with: Array(input[len - tailSize..<len]))
        
        var hash = UInt128()
        
        if numChunks > 0 {
            // Hash the first 128 bytes
            hash = hashChunk(chunk: input, size: 128)
            
        } else {
            // Hash the tail
            hash = hashChunk(chunk: tail, size: tailSize)
        }
        
        hash = UInt128.add128(left: hash, right: ROUND_MAGIC)
        
        if numChunks > 0 {
            for i in 1..<numChunks {
                let offset = 128 * i
                let offsetChunk = Array(input[offset..<128 + offset])
                hash = hashMuladd(hash: hash, mul: ROUND_MAGIC, add: hashChunk(chunk: offsetChunk, size: 128))
            }
            
            if tailSize > 0 {
                hash = hashMuladd(hash: hash, mul: ROUND_MAGIC, add: hashChunk(chunk: tail, size: tailSize))
            }
        }
        
        // Finalize the hash
        hash = UInt128.add128(left: hash, right: UInt128(upperBits: UInt64(tailSize * 8), lowerBits: 0))
        if UInt128.cmp128(left: hash, right: UInt128(upperBits: 0x7fffffffffffffff, lowerBits: 0xffffffffffffffff)) >= 0 {
            hash = UInt128.add128(left: hash, right: UInt128(upperBits: 0, lowerBits: 1))
        }
        hash = UInt128.and128(left: hash, right: UInt128(upperBits: 0x7fffffffffffffff, lowerBits: 0xffffffffffffffff))
        
        let hashHigh = hash.high
        let hashLow = hash.low
        
        var X = hashHigh &+ HI(n: hashLow)
        X = HI(n: X &+ HI(n: X) &+ 1) &+ hashHigh
        let Y = (X << 32) &+ hashLow
        
        var A = X &+ FINAL_MAGIC0
        if (A < X) {
            A = A &+ 0x101
        }
        
        var B = Y &+ FINAL_MAGIC1
        if (B < Y) {
            B = B &+ 0x101
        }
        
        var H = UInt128.mul64(lhs: A, rhs: B)
        H = UInt128.add128(left: UInt128.mul64(lhs: 0x101, rhs: H.high), right: UInt128(upperBits: 0, lowerBits: H.low))
        H = UInt128.add128(left: UInt128.mul64(lhs: 0x101, rhs: H.high), right: UInt128(upperBits: 0, lowerBits: H.low))
        
        if H.high > 0 {
            H = UInt128.add128(left: H, right: UInt128(upperBits: 0, lowerBits: 0x101))
        }
        if H.low > 0xFFFFFFFFFFFFFEFE {
            H = UInt128.add128(left: H, right: UInt128(upperBits: 0, lowerBits: 0x101))
        }
        
        return H.low
    }
    
    private static func hashChunk(chunk: [UInt8], size: Int) -> UInt128 {
        var hash = UInt128()
        for i in 0..<8 {
            let offset = i * 16
            if offset >= size {
                break
            }
            let a = UnsafeConverter.bytesAsUInt64(Array(chunk[offset..<offset + 8]))
            let b = UnsafeConverter.bytesAsUInt64(Array(chunk[offset + 8..<offset + 16]))
            hash = UInt128.add128(left: hash, right: UInt128.mul64(lhs: a &+ magic_table[i * 2], rhs: b &+ magic_table[i * 2 + 1]))
        }
        return UInt128.and128(left: hash, right: UInt128(upperBits: 0x3fffffffffffffff, lowerBits: 0xffffffffffffffff))
    }
    
    private static func hashMuladd(hash: UInt128, mul: UInt128, add: UInt128) -> UInt128 {
        let a0 = LO(n: add.low), a1 = HI(n: add.low), a23 = add.high
        let m0 = LO(n: mul.low), m1 = HI(n: mul.low)
        let m2 = LO(n: mul.high), m3 = HI(n: mul.high)
        let h0 = LO(n: hash.low), h1 = HI(n: hash.low)
        let h2 = LO(n: hash.high), h3 = HI(n: hash.high)
        
        /* Column sums, before carry */
        let c0 = (h0 &* m0)
        let c1 = (h0 &* m1) &+ (h1 &* m0)
        let c2 = (h0 &* m2) &+ (h1 &* m1) &+ (h2 &* m0)
        let c3 = (h0 &* m3) &+ (h1 &* m2) &+ (h2 &* m1) &+ (h3 &* m0)
        let c4 = (h1 &* m3) &+ (h2 &* m2) &+ (h3 &* m1)
        let c5 = (h2 &* m3) &+ (h3 &* m2)
        let c6 = (h3 &* m3)
        
        /* Combine, add, and carry (bugs included) */
        let r2 = c2 &+ (c6 << 1) &+ a23
        let r3 = c3 &+ HI(n: r2)
        let r0 = c0 &+ (c4 << 1) &+ a0 &+ (r3 >> 31)
        let r1 = c1 &+ (c5 << 1) &+ a1 &+ HI(n: r0)
        
        /* Return as uint128_t */
        return UInt128(upperBits:(((r3 << 33) >> 1) | LO(n: r2)) &+ HI(n: r1), lowerBits: (r1 << 32) | LO(n: r0))
    }
}
