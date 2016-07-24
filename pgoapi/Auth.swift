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

    func login(username:String, password:String) {
        print("Starting login...")
        self.username = username
        self.password = password

        // Disable redirects
        let delegate = Alamofire.Manager.sharedInstance.delegate
        delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
            return nil
        }

        // Add "niantic" as the User-Agent
        let manager = Manager.sharedInstance
        manager.session.configuration.HTTPAdditionalHeaders = [
            "User-Agent": "niantic"
        ]

        // Request login info
        Alamofire.request(.GET, Endpoint.LoginInfo)
            .responseJSON { response in
                if let JSON = response.result.value {
                    let lt = JSON["lt"] as! String
                    let execution = JSON["execution"] as! String
                    print("Got login information!\nlt: \(lt)\nexecution: \(execution)")
                    self.getTicket(lt, execution: execution)
                }
        }
    }

    func getTicket(lt: String, execution: String) {
        print("Requesting ticket...")

        let parameters = [
            "lt": lt,
            "execution": execution,
            "_eventId": "submit",
            "username": username,
            "password": password
        ]

        Alamofire.request(.POST, Endpoint.LoginInfo, parameters: parameters)
            .responseData { response in
                if let location = response.response!.allHeaderFields["Location"] as? String {
                    let ticketRange = location.rangeOfString("?ticket=")
                    let ticket = String(location.characters.suffixFrom(ticketRange!.endIndex))
                    print("Got ticket: \(ticket)")
                    self.loginOauth(ticket)
                } else {
                    self.delegate?.didNotReceiveAuth()
                }
            }
    }

    func loginOauth(ticket: String) {
        print("Logging in via OAuth...")

        let parameters = [
            "client_id": "mobile-app_pokemon-go",
            "redirect_uri": "https://www.nianticlabs.com/pokemongo/error",
            "client_secret": "w8ScCUXJQc6kXKw8FiOhd8Fixzht18Dq3PEVkUCP5ZPxtgyWsbTvWHFLm2wNY0JR",
            "grant_type": "refresh_token",
            "code": ticket
        ]

        // Remove "niantic" from the User-Agent
        let manager = Manager.sharedInstance
        manager.session.configuration.HTTPAdditionalHeaders = [:]

        Alamofire.request(.POST, Endpoint.LoginOAuth, parameters: parameters)
            .responseString { response in
                let value = response.result.value!
                let regex = try! NSRegularExpression(pattern: "access_token=([A-Za-z0-9\\-.]+)&expires=([0-9]+)", options: [])
                let matches = regex.matchesInString(value, options: [], range: NSRange(location: 0, length: value.utf16.count))

                // Extract the access_token
                let atRange = matches[0].rangeAtIndex(1)
                let atSwiftRange = atRange.rangeForString(value)!
                self.accessToken = value.substringWithRange(atSwiftRange)

                // Extract the expires
                let eRange = matches[0].rangeAtIndex(1)
                let eSwiftRange = eRange.rangeForString(value)!
                self.expires = value.substringWithRange(eSwiftRange)

                self.loggedIn = true
                print("Login successful!\nAccess token: \(self.accessToken)")
                self.delegate?.didReceiveAuth()
            }
    }

}
