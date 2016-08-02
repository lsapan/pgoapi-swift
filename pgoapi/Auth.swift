//
//  Auth.swift
//  Pokemon GO Map
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire

class Auth {
    static let sharedInstance = Auth()

    var username: String!
    var password: String!
    var accessToken: String?
    var expires: String?
    var loggedIn: Bool = false
    var delegate: AuthDelegate?

    func login(username:String, password:String, provider: AuthType = .Ptc) {
        self.username = username
        self.password = password
        
        if provider == .Ptc {
            PtcOAuth.sharedInstance.login(withUsername: username, withPassword: password)
        } else if provider == .Google {
            GPSOAuth.sharedInstance.login(withEmail: username, withPassword: password)
        }
    }
}
