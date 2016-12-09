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

    var auth: PGoAuth!
    var request: PGoApiRequest? = nil
    var mapCells = Pogoprotos.Networking.Responses.GetMapObjectsResponse()
    
    enum AuthMethod {
        case PTC
        case Google
    }
    
    @IBOutlet weak var authSegment: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var latField: UITextField!
    @IBOutlet weak var longField: UITextField!
    
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
        if usernameTextField.text! == "" || passwordTextField.text! == "" {
            showAlert("Error", message: "Login details are incomplete.")
            return
        }
        if let long = Double(longField.text!), lat = Double(latField.text!) {
            if -180 <= long && long <= 180 && -90 <= lat && lat <= 90 {
                print("Using latitude: \(lat) and longitude: \(long).")
            } else {
                showAlert("Error", message: "Latitude and longitude values are invalid.")
                return
            }
        } else {
            showAlert("Error", message: "Latitude and longitude values are invalid.")
            return
        }
        auth.login(withUsername: usernameTextField.text!, withPassword: passwordTextField.text!)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "showMap") {
            let pokeMap:PokemonMap = segue.destinationViewController as! PokemonMap
            pokeMap.mapCells = mapCells
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        auth = PtcOAuth()
        auth.delegate = self

        latField.text! = String(37.33161821509)
        longField.text! = String(-122.0298043927)
    }
    
    func didReceiveAuth() {
        print("Auth received!!")
        print("Starting simulation...")

        // Init the api with successful auth
        request = PGoApiRequest(auth: auth)
        
        // Set the latitude/longitude of player. 
        // Altitude should be included, but it is optional and defaults to 10.1
        request!.setLocation(Double(latField.text!)!, longitude: Double(longField.text!)!, altitude: 10.1)
        
        // Simulate the start, which cues methods: 
        // getPlayer(), getHatchedEggs(), getInventory(), checkAwardedBadges(), downloadSettings()
        // Results can be accessed in subresponse for intent .Login under didReceiveApiResponse()
        request!.simulateAppStart()
        request!.makeRequest(.Login, delegate: self)
    }
    
    func didNotReceiveAuth() {
        showAlert("Error", message: "Failed to auth.")
        print("Failed to auth!")
    }
    
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print("Got that API response: \(intent)")
        // Uncomment the following to view the responses
        // print(response.response)
        // print(response.subresponses)
        
        if (intent == .Login) {
            // App simulation complete, now requesting map objects
            request!.getMapObjects()
            request!.makeRequest(.GetMapObjects, delegate: self)
        } else if (intent == .GetMapObjects) {
            print("Got map objects!")
            
            // Map cells are the first subresponse
            mapCells = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetMapObjectsResponse
            
            performSegueWithIdentifier("showMap", sender: nil)
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
    
    func didReceiveApiException(intent: PGoApiIntent, exception: PGoApiExceptions) {
        print("API Exception: \(exception)")
    }
}

