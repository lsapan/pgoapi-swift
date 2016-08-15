//
//  PGoEncryptHelper.swift
//  Pods
//
//  Created by PokemonGoSucks on 2016-08-09.
//
//

import Foundation


public class PGoEncryptHelper {
    public func encryptUInt32(input_: Array<UInt32>) -> Array<UInt32> {
        var output = Array<UInt32>(count: 64, repeatedValue: 0)
                
        if (output.count != 64) {
            return []
        }
        
        var input = Array<UInt32>(count: 203, repeatedValue: 0)
        
        input = subFuncA().subFuncA(input, data_: input_)
        input = subFuncB().subFuncB(input)
        input = subFuncC().subFuncC(input)        
        input = subFuncD().subFuncD(input)
        input = subFuncE().subFuncE(input)
        input = subFuncF().subFuncF(input)
        input = subFuncG().subFuncG(input)
        input = subFuncH().subFuncH(input)
        input = subFuncI().subFuncI(input)
        input = subFuncJ().subFuncJ(input)
        input = subFuncK().subFuncK(input)
        input = subFuncL().subFuncL(input)
        output = subFuncM().subFuncM(input, output_: output)

        return output
    }
}