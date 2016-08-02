//
//  GPSOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import Alamofire

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
    
    private let headers = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    var email: String!
    var password: String!
    var accessToken: String?
    var token: String?
    var expires: Int?
    
    private func parseKeyValues(body:String) -> Dictionary<String, String> {
        var obj = [String:String]()
        let bodySplit = body.componentsSeparatedByString("\n")
        for values in bodySplit {
            var keysValues = values.componentsSeparatedByString("=")
            obj[keysValues[0]] = keysValues[1]
        }
        return obj;
    }
    
    private func getTicket() {
        var params = baseParams
        params["Email"] = GPSOAuth.sharedInstance.email
        params["Passwd"] = GPSOAuth.sharedInstance.password
        params["service"] = "ac2dm"
        
        Alamofire.request(.POST, Endpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Token"] != nil {
                    self.loginOAuth(googleDict["Token"]!)
                    GPSOAuth.sharedInstance.token = googleDict["Token"]
                } else {
                    Auth.sharedInstance.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    private func loginOAuth(token: String) {
        var params = baseParams
        params["Email"] = GPSOAuth.sharedInstance.email
        params["EncryptedPasswd"] = token
        params["service"] = "audience:server:client_id:848232511240-7so421jotr2609rmqakceuu1luuq0ptb.apps.googleusercontent.com"
        params["app"] = "com.nianticlabs.pokemongo"
        params["client_sig"] = "321187995bc7cdc2b5fc91b11a96e2baa8602c62"
        
        Alamofire.request(.POST, Endpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Auth"] != nil {
                    GPSOAuth.sharedInstance.accessToken = googleDict["Auth"]!
                    GPSOAuth.sharedInstance.expires = Int(googleDict["Expiry"]!)!
                    Auth.sharedInstance.loggedIn = true
                    Auth.sharedInstance.delegate?.didReceiveAuth()
                } else {
                    Auth.sharedInstance.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    func login(withEmail email: String, withPassword password: String) {
        GPSOAuth.sharedInstance.email = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        GPSOAuth.sharedInstance.password = password.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        Endpoint.LoginProvider = "\(AuthType.Google)"
        
        self.getTicket()
    }
}