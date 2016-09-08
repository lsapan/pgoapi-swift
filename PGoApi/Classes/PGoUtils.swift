//
//  PGoUtils.swift
//  pgoapi
//
//  Created by PokemonGoSucks on 2016-08-03.
//
//

import Foundation
import CoreLocation
import MapKit
import Alamofire


public class PGoLocationUtils {
    public enum unit {
        case Kilometers, Miles, Meters, Feet
    }
    
    public enum bearingUnits {
        case Degree, Radian
    }
    
    public init () {}
    
    public struct PGoCoordinate {
        public var latitude: Double?
        public var longitude: Double?
        public var altitude: Double?
        public var distance: Double?
        public var displacement: Double?
        public var address: [NSObject: AnyObject]?
        public var mapItem: MKMapItem?
    }
    
    public struct PGoDirections {
        public var coordinates: Array<PGoLocationUtils.PGoCoordinate>
        public var duration: Double
    }
    
    public func getAltitudeAndHorizontalAccuracy(latitude latitude: Double, longitude: Double, completionHandler: (altitude: Double?, horizontalAccuracy: Double?) -> ()) {
        /*
         
         Example func for completionHandler:
         func receiveAltitudeAndHorizontalAccuracy(altitude: Double?, horizontalAccuracy: Double?)
         
         */
        Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/elevation/json?locations=\(latitude),\(longitude)&sensor=false", parameters: nil)
            .responseJSON { response in
                var altitude:Double? = nil
                var horizontalAccuracy:Double? = nil

                if let JSON = response.result.value {
                    let dict = JSON as! [String:AnyObject]
                    if let result = dict["results"] as? [[String:AnyObject]] {
                        if result.count > 0 {
                            if let alt = result[0]["elevation"] as? Double {
                                altitude = alt
                            }
                            if let horAcc = result[0]["resolution"] as? Double {
                                horizontalAccuracy = horAcc
                            }
                        }
                    }
                    completionHandler(altitude: altitude, horizontalAccuracy: horizontalAccuracy)
                } else {
                    completionHandler(altitude: nil, horizontalAccuracy: nil)
                }
        }
    }
    
    public func reverseGeocode(latitude: Double, longitude: Double, completionHandler: (PGoLocationUtils.PGoCoordinate?) -> ()) {
        /*
         
         Example func for completionHandler:
         func receivedReverseGeocode(results:PGoLocationUtils.PGoCoordinate?)
         
         */
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placeData, error) -> Void in
            if placeData?.count > 0 {
                let addressDictionary = placeData![0]
                let address = addressDictionary.addressDictionary!
                let result = PGoCoordinate(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: nil,
                    distance: nil,
                    displacement: nil,
                    address: address,
                    mapItem: MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: placeData![0].location!.coordinate,
                            addressDictionary: placeData![0].addressDictionary as! [String:AnyObject]?
                        )
                    )
                )
                completionHandler(result)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    public func geocode(location: String, completionHandler: (PGoLocationUtils.PGoCoordinate?) -> ()) {
        /*
         
         Example func for completionHandler:
         func receivedGeocode(results:PGoLocationUtils.PGoCoordinate?)
         
        */
        
        var result: PGoCoordinate?
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location, completionHandler: {(placeData: [CLPlacemark]?, error: NSError?) -> Void in
            if (placeData?.count > 0) {
                let addressDictionary = placeData![0]
                result = PGoCoordinate(
                    latitude: (placeData![0].location?.coordinate.latitude)!,
                    longitude: (placeData![0].location?.coordinate.longitude)!,
                    altitude: placeData![0].location?.altitude,
                    distance: nil,
                    displacement: nil,
                    address: addressDictionary.addressDictionary!,
                    mapItem: MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: placeData![0].location!.coordinate,
                            addressDictionary: placeData![0].addressDictionary as! [String:AnyObject]?
                        )
                    )
                )
                completionHandler(result)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    public func getDistanceBetweenPoints(startLatitude:Double, startLongitude:Double, endLatitude:Double, endLongitude: Double, unit: PGoLocationUtils.unit? = .Meters) -> Double {
        
        let start = CLLocation.init(latitude: startLatitude, longitude: startLongitude)
        let end = CLLocation.init(latitude: endLatitude, longitude: endLongitude)
        var distance = start.distanceFromLocation(end)
        
        if unit == .Miles {
            distance = distance/1609.344
        } else if unit == .Kilometers {
            distance = distance/1000
        } else if unit == .Feet {
            distance = distance * 3.28084
        }
        return distance
    }
    
    public func moveDistanceToPoint(startLatitude:Double, startLongitude:Double, endLatitude:Double, endLongitude: Double, distance: Double, unitOfDistance: PGoLocationUtils.unit? = .Meters) -> PGoLocationUtils.PGoCoordinate {
        let maxDistance = getDistanceBetweenPoints(startLatitude, startLongitude: startLongitude, endLatitude: endLatitude, endLongitude: endLongitude)
        
        var distanceConverted = distance
        if unitOfDistance == .Miles {
            distanceConverted = distance * 1609.344
        } else if unitOfDistance == .Kilometers {
            distanceConverted = distance * 1000
        } else if unitOfDistance == .Feet {
            distanceConverted = distance / 3.28084
        }
        
        var distanceMove = distanceConverted/maxDistance
        
        if distanceMove > 1 {
            distanceMove = 1
        }
        
        return PGoCoordinate(
            latitude: startLatitude + ((endLatitude - startLatitude) * distanceMove),
            longitude: startLongitude + ((endLongitude - startLongitude) * distanceMove),
            altitude: nil,
            distance: maxDistance,
            displacement: distanceMove * maxDistance,
            address: nil,
            mapItem: nil
        )
    }
    
    public func moveDistanceWithBearing(startLatitude:Double, startLongitude:Double, bearing: Double, distance: Double, bearingUnits: PGoLocationUtils.bearingUnits? = .Radian, unitOfDistance: PGoLocationUtils.unit? = .Meters) -> PGoLocationUtils.PGoCoordinate {
        
        var distanceConverted = distance
        if unitOfDistance == .Miles {
            distanceConverted = distance * 1609.344
        } else if unitOfDistance == .Kilometers {
            distanceConverted = distance * 1000
        } else if unitOfDistance == .Feet {
            distanceConverted = distance / 3.28084
        }
        
        var bearingConverted = bearing
        if bearingUnits == .Degree {
            bearingConverted = bearing * M_PI / 180.0
        }
        
        let distanceRadian = distanceConverted / (6372797.6)
        
        let lat = startLatitude * M_PI / 180
        let long = startLongitude * M_PI / 180
        
        let latitude = (asin(sin(lat) * cos(distanceRadian) + cos(lat) * sin(distanceRadian) * cos(bearingConverted))) * 180 / M_PI
        let longitude = (long + atan2(sin(bearingConverted) * sin(distanceRadian) * cos(lat), cos(distanceRadian) - sin(lat) * sin(latitude))) * 180 / M_PI
        
        return PGoCoordinate(
            latitude: latitude,
            longitude: longitude,
            altitude: nil,
            distance: nil,
            displacement: nil,
            address: nil,
            mapItem: nil
        )
    }
    
    private func getMKMapItem(lat: Double, long: Double) -> MKMapItem {
        let sourceLoc2D = CLLocationCoordinate2DMake(lat, long)
        let sourcePlacemark = MKPlacemark(coordinate: sourceLoc2D, addressDictionary: nil)
        let source = MKMapItem(placemark: sourcePlacemark)
        return source
    }
    
    public func getDirectionsFromToLocations(startLatitude:Double, startLongitude:Double, endLatitude:Double, endLongitude: Double, transportType: MKDirectionsTransportType? = .Walking, completionHandler: (PGoLocationUtils.PGoDirections?) -> ()) {
        
        /*
         
         Example func for completionHandler:
         func receivedDirections(result: PGoLocationUtils.PGoDirections?)
         
         */
        
        var result:Array<PGoCoordinate> = []
        
        let request: MKDirectionsRequest = MKDirectionsRequest()
        let start = getMKMapItem(startLatitude, long: startLongitude)
        let end = getMKMapItem(endLatitude, long: endLongitude)
        
        request.source = start
        request.destination = end
        request.requestsAlternateRoutes = true
        request.transportType = transportType!
        
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler ({
            (response: MKDirectionsResponse?, error: NSError?) in
            if let routeResponse = response?.routes {
                let fastestRoute: MKRoute =
                    routeResponse.sort({$0.expectedTravelTime <
                        $1.expectedTravelTime})[0]
                
                for step in fastestRoute.steps {
                    result.append(
                        PGoCoordinate(
                            latitude: step.polyline.coordinate.latitude,
                            longitude: step.polyline.coordinate.longitude,
                            altitude: nil,
                            distance: step.distance,
                            displacement: nil,
                            address: nil,
                            mapItem: nil
                        )
                    )
                }
                completionHandler(
                    PGoLocationUtils.PGoDirections(
                        coordinates: result,
                        duration: fastestRoute.expectedTravelTime
                    )
                )
            } else {
                completionHandler(nil)
            }
        })
    }
}
