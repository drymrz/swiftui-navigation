//
//  LocationManager.swift
//  exploreMapKit
//
//  Created by Adry Mirza on 24/10/23.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var heading: CLLocationDirection = 0.0
    @Published var speed: String?
    
    @Published var isDriving: Bool = false
    private var drivingStateTimer: Timer?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.startUpdatingHeading()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        startSpeedCheck()
    }
    
    func startSpeedCheck() {
        // if drivingStateTimer is not set, create new one.
        if drivingStateTimer === nil {
            drivingStateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] timer in
                if (Double(String(speed ?? "0")) ?? 0 > 4.16667) {
                    self.isDriving = true
                } else {
                    self.isDriving = false
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            self.location = location
        }
        if let speed = locations.last?.speed {
            self.speed = speed.description
            print(speed.description)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            heading = newHeading.trueHeading
    }
}









