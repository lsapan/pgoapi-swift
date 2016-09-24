//
//  GPSOAuth.swift
//  pgoapi
//
//  Created by Rowell Heria on 02/08/2016.
//  Created by Brian Barton on 9/4/16.
//  
//

import Foundation
import Alamofire


public class GPSOAuth: PGoAuth {
    static public let LOGIN_URL = "https://accounts.google.com/o/oauth2/auth?client_id=848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=openid%20email%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email"
    private let OAUTH_TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v4/token"
    private let SECRET = "NCjF1TLi2CcY6t5mt0ZveuL7"
    private let CLIENT_ID = "848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com"
    
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
    
    public var email: String!
    public var password: String!
    public var token: String?
    public var accessToken: String?
    public var expires: Int?
    public var expired: Bool = false
    public var loggedIn: Bool = false
    public var delegate: PGoAuthDelegate?
    public var authType: PGoAuthType = .Google
    public var endpoint: String = PGoEndpoint.Rpc
    public var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    public var manager: Manager
    public var banned: Bool = false
    private var refreshToken: String?

    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        manager = Alamofire.Manager(configuration: configuration)
    }
    
    private func parseKeyValues(body:String) -> Dictionary<String, String> {
        var obj = [String:String]()
        let bodySplit = body.componentsSeparatedByString("\n")
        for values in bodySplit {
            var keysValues = values.componentsSeparatedByString("=")
            if keysValues.count >= 2 {
                obj[keysValues[0]] = keysValues[1]
            }
        }
        return obj;
    }
    
    private func getTicket() {
        var params = baseParams
        params["Email"] = self.email
        params["Passwd"] = self.password
        params["service"] = "ac2dm"
        
        manager.request(.POST, PGoEndpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Token"] != nil {
                    self.loginOAuth(googleDict["Token"]!)
                    self.token = googleDict["Token"]
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    private func loginOAuth(token: String) {
        var params = baseParams
        params["Email"] = self.email
        params["EncryptedPasswd"] = token
        params["service"] = "audience:server:client_id:848232511240-7so421jotr2609rmqakceuu1luuq0ptb.apps.googleusercontent.com"
        params["app"] = "com.nianticlabs.pokemongo"
        params["client_sig"] = "321187995bc7cdc2b5fc91b11a96e2baa8602c62"
        
        manager.request(.POST, PGoEndpoint.GoogleLogin, parameters: params, headers: headers, encoding: .URLEncodedInURL)
            .responseJSON { (response) in
                let responseString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                let googleDict = self.parseKeyValues(responseString! as String)
                
                if googleDict["Auth"] != nil {
                    self.accessToken = googleDict["Auth"]!
                    self.expires = Int(googleDict["Expiry"]!)!
                    self.loggedIn = true
                    self.delegate?.didReceiveAuth()
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    private func cleanCookies() {
        if let cookies = manager.session.configuration.HTTPCookieStorage?.cookies {
            for cookie in cookies {
                manager.session.configuration.HTTPCookieStorage?.deleteCookie(cookie)
            }
        }
    }
    
    public func login(withUsername username: String, withPassword password: String) {
        self.email = username.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        self.password = password
        
        self.cleanCookies()
        
        self.getTicket()
    }
    
    private func refreshAccessToken() {
        manager.request(.POST, OAUTH_TOKEN_ENDPOINT, parameters: [
            "client_id": CLIENT_ID,
            "client_secret": SECRET,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken!
            ]).validate().responseJSON { response in
                switch response.result {
                case .Success(let data):
                    if let json = data as? NSDictionary,
                        let token = json["id_token"] as? String,
                        let expiresIn = json["expires_in"] as? Int? {
                        self.authToken = nil
                        self.accessToken = token
                        self.expires = expiresIn
                        self.expired = false
                        self.delegate?.didReceiveAuth()
                    } else {
                        self.delegate?.didNotReceiveAuth()
                    }
                case .Failure:
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
    
    // username is not used and password is oauth code user receives after approving access
    public func login(withToken token: String) {
        // refresh the token if it has expired
        if loggedIn && expired {
            refreshAccessToken()
            return
        }
        
        manager.request(.POST, OAUTH_TOKEN_ENDPOINT, parameters: [
            "code": token,
            "client_id": CLIENT_ID,
            "client_secret": SECRET,
            "grant_type": "authorization_code",
            "scope": "openid email https://www.googleapis.com/auth/userinfo.email",
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob"
            ]).validate().responseJSON { response in
                switch response.result {
                case .Success(let data):
                    if let json = data as? NSDictionary,
                        let idToken = json["id_token"] as? String,
                        let refreshToken = json["refresh_token"] as? String,
                        let expires = json["expires_in"] as? Int {
                        self.accessToken = idToken
                        self.refreshToken = refreshToken
                        self.loggedIn = true
                        self.expires = expires
                        self.delegate?.didReceiveAuth()
                    } else {
                        self.delegate?.didNotReceiveAuth()
                    }
                case .Failure:
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }

}
