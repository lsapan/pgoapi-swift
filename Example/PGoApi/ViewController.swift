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

    var auth: PtcOAuth!
    var request = PGoApiRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        auth = PtcOAuth()
        auth.delegate = self
        auth.login(withUsername: "", withPassword: "")
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")

        // Init with auth
        request = PGoApiRequest(auth: auth)
        
        // Set the latitude/longitude of player; altitude should be included, but it's optional
        request.setLocation(37.331686, longitude: -122.030765, altitude: 1.0)
        
        // Simulate the start
        request.simulateAppStart()
        request.makeRequest(.Login, delegate: self)
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("Got that API response: \(intent)")
        if (intent == .Login) {
            request.getMapObjects()
            request.makeRequest(.GetMapObjects, delegate: self)
        } else if (intent == .GetMapObjects) {
            print("Got map objects!")
            print(response.response)
            print(response.subresponses)
            let r = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetMapObjectsResponse
            let cell = r.mapCells[0]
            print(cell.nearbyPokemons)
            print(cell.wildPokemons)
            print(cell.catchablePokemons)
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }

}

