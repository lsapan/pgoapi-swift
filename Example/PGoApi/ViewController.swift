//
//  ViewController.swift
//  PGoApi
//
//  Created by Luke Sapan on 08/02/2016.
//  Copyright (c) 2016 Luke Sapan. All rights reserved.
//

import UIKit
import PGoApi

class ViewController: UIViewController, PGoAuthDelegate, PGoApiDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        PGoAuth.sharedInstance.delegate = self
        PGoAuth.sharedInstance.login("pokefan5370", password: "pokefan5370")
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")
        let request = PGoApiRequest()
        request.simulateAppStart()
        request.makeRequest(.Login, delegate: self)
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: ApiIntent, response: ApiResponse) {
        print("Got that API response: \(intent)")
        if (intent == .Login) {
            Api.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(Api.endpoint)")
            let request = PGoApiRequest()
            request.getMapObjects(37.331686, longitude: -122.030765)
            request.makeRequest(.GetMapObjects, delegate: self)
        } else if (intent == .GetMapObjects) {
            print("Got map objects!")
            print(response.response)
            print(response.subresponses)
        }
    }
    
    func didReceiveApiError(intent: ApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }


}

