import Foundation
import CoreLocation

/// A model representing a location for searching and displaying on maps
struct Location: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let city: String?
    let state: String?
    let country: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: String, 
         name: String, 
         address: String, 
         latitude: Double, 
         longitude: Double, 
         city: String? = nil, 
         state: String? = nil, 
         country: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.state = state
        self.country = country
    }
} 