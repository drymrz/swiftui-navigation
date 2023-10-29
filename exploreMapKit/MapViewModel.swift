//
//  MapViewModel.swift
//  exploreMapKit
//
//  Created by Adry Mirza on 27/10/23.
//

import SwiftUI
import MapKit

class MapViewModel: ObservableObject{
    @Published var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @Published var isNavigating = false
    @Published var navigationCameraTimer: Timer?
}
