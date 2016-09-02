//
//  PokemonMap.swift
//  PGoApi
//
//  Created by PokemonGoSucks on 2016-08-21.
//
//

import UIKit
import MapKit
import PGoApi


class PokemonMap: UIViewController, MKMapViewDelegate {
    var mapCells = Pogoprotos.Networking.Responses.GetMapObjectsResponse()
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for mapCell in mapCells.mapCells {
            let forts = mapCell.forts
            let spawnPoints = mapCell.spawnPoints
            let pokemons = mapCell.catchablePokemons
            let wildPokemon = mapCell.wildPokemons
            
            for fort in forts {
                if (fort.hasGymPoints) {
                    annotate(fort.latitude, long: fort.longitude, name: "Gym owned by \(fort.ownedByTeam)")
                } else {
                    annotate(fort.latitude, long: fort.longitude, name: "Pokestop")
                }
            }
            
            for spawnPoint in spawnPoints {
                annotate(spawnPoint.latitude, long: spawnPoint.longitude, name: "Spawnpoint")
            }
            
            for pokemon in pokemons {
                annotate(pokemon.latitude, long: pokemon.longitude, name: "Pokemon \(pokemon.pokemonId)")
            }
            
            for pokemon in wildPokemon {
                annotate(pokemon.latitude, long: pokemon.longitude, name: "Pokemon \(pokemon.pokemonData.pokemonId)")
            }
        }
        
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
    
    func annotate(lat: Double, long: Double, name: String) {
        let mapObject = CLLocationCoordinate2DMake(lat, long)
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = mapObject
        dropPin.title = name
        mapView.addAnnotation(dropPin)
    }
}