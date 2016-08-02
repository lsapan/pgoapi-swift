//
//  GPSOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
class GPSOAuth {
    static let sharedInstance = GPSOAuth()
    
    private let baseParams = [
        "accountType": "HOSTED_OR_GOOGLE",
        "has_permission": "1",
        "add_account": "1",
        "source": "android",
        "androidId": "9774d56d682e549c",
        "device_country": "us",
        "operatorCountry": "us",
        "lang": "en",
        "sdk_version": "17"
    ]
    
    var email: String!
    var password: String!
    var accessToken: String?
    var token: String?
    var expires: Int?
    
    func getTicket(email: String, password: String) {
        
    }
    
    func loginOAuth(token: String) {
        
    }
}