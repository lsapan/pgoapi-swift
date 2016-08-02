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
        PGoAuth.sharedInstance.login("", password: "")
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
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("Got that API response: \(intent)")
        if (intent == .Login) {
            PGoSetting.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(PGoSetting.endpoint)")
            let request = PGoApiRequest()
            
            //Set the latitude/longitude of player; altitude is optional
            request.setLocation(37.331686, longitude: -122.030765, altitude: 0)
            
            request.getMapObjects()
            request.makeRequest(.GetMapObjects, delegate: self)
        } else if (intent == .GetMapObjects) {
            print("Got map objects!")
            print(response.response)
            print(response.subresponses)
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }


}

