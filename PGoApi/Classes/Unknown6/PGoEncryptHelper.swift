//
//  PGoEncryptHelper.swift
//  Pods
//
//  Created by PokemonGoSucks on 2016-08-09.
//
//

import Foundation


internal class PGoEncryptHelper {
    internal static func encryptUInt32(_ data: Array<UInt32>) -> Array<UInt32> {
        var output = Array<UInt32>(repeating: 0, count: 64)
        var input = Array<UInt32>(repeating: 0, count: 203)
        
        subFuncA().subFuncA(&input, input: data)
        subFuncB().subFuncB(&input)
        subFuncC().subFuncC(&input)
        subFuncD().subFuncD(&input)
        subFuncE().subFuncE(&input)
        subFuncF().subFuncF(&input)
        subFuncG().subFuncG(&input)
        subFuncH().subFuncH(&input)
        subFuncI().subFuncI(&input)
        subFuncJ().subFuncJ(&input)
        subFuncK().subFuncK(&input)
        subFuncL().subFuncL(&input)
        subFuncM().subFuncM(&input, output: &output)
        
        return output
    }
}
