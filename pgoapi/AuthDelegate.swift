//
//  AuthDelegate.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


protocol AuthDelegate {
    func didReceiveAuth()
    func didNotReceiveAuth()
}
