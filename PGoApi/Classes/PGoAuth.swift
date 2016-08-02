//
//  Auth.swift
//  Pokemon GO Map
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire

public class PGoAuth {
    public static let sharedInstance = PGoAuth()

    var username: String!
    var password: String!
    public var accessToken: String?
    public var expires: String?
    public var loggedIn: Bool = false
    public var delegate: PGoAuthDelegate?

    public func login(username:String, password:String, provider: AuthType = .Ptc) {
        self.username = username
        self.password = password
        
        if provider == .Ptc {
            PtcOAuth.sharedInstance.login(withUsername: username, withPassword: password)
        } else if provider == .Google {
            GPSOAuth.sharedInstance.login(withEmail: username, withPassword: password)
        }
    }
}
