//
//  AuthDelegate.swift
//  pgomap
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation


public protocol PGoAuthDelegate {
    func didReceiveAuth()
    func didNotReceiveAuth()
}
