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
    
    enum AuthMethod {
        case PTC
        case Google
    }
    
    @IBOutlet weak var authSegment: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func login(sender: UIButton) {
        switch authSegment.selectedSegmentIndex {
        case AuthMethod.PTC.hashValue:
            auth = PtcOAuth()
        case AuthMethod.Google.hashValue:
            auth = GPSOAuth()
        default:
            break
        }
        
        auth.delegate = self
        auth.login(withUsername: usernameTextField.text!, withPassword: passwordTextField.text!)
    }
    
    var auth: PGoAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")
        let request = PGoApiRequest()
        request.simulateAppStart()
        request.makeRequest(.Login, auth: auth, delegate: self)
    }
    
    func didNotReceiveAuth() {
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("Got that API response: \(intent)")
        if (intent == .Login) {
            auth.endpoint = "https://\((response.response as! Pogoprotos.Networking.Envelopes.ResponseEnvelope).apiUrl)/rpc"
            print("New endpoint: \(auth.endpoint)")
            let request = PGoApiRequest()
            
            //Set the latitude/longitude of player; altitude is optional
//            request.setLocation(37.331686, longitude: -122.030765, altitude: 0)
            request.getInventory()
            request.makeRequest(.GetInventory, auth: auth, delegate: self)
            
//            request.getMapObjects()
//            request.makeRequest(.GetMapObjects, auth: auth, delegate: self)
        } else if (intent == .GetMapObjects) {
            print("Got map objects!")
            print(response.response)
            print(response.subresponses)
            let r = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetMapObjectsResponse
            let cell = r.mapCells[0]
            print(cell.nearbyPokemons)
            print(cell.wildPokemons)
            print(cell.catchablePokemons)
        } else if (intent == .GetInventory) {
            print("Got inventory!")
            print(response.response)
            print(response.subresponses)
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }


}

