//
//  NavigationView.swift
//  exploreMapKit
//
//  Created by Adry Mirza on 25/10/23.
//

import SwiftUI
import CoreLocation
import MapKit

struct NavigationView: View {
//    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @ObservedObject var vm = MapViewModel()
    @ObservedObject var locationManager = LocationManager()
    @State private var route: MKRoute?
    @Namespace var mapScope
    @State var mapStyle: MapStyle = .standard(elevation: .realistic, showsTraffic: true)
    @State var isNavigating = false
    @State var routeInstruction: [String] = []
    @State var routeDistance: [String] = []
    @State var selectedTabIndex: Int = 0
    @State var headingFromLM: Double = 0
    var destination: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 1.085721, longitude: 103.904802)
    @State var isCameraFollowing: Bool = false
    @State var cameraButtonPressed: Bool = false
    @State var currentStep: Int = 0
    
    init(){
        headingFromLM = locationManager.heading
    }
    
    var body: some View {
        ZStack{
            Map(position: $vm.cameraPosition, scope: mapScope){
                if let route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
                UserAnnotation()
            }
            .onAppear(){
                getDirections()
            }
            
            VStack{
                
                if isNavigating{
                    TabView(selection: $selectedTabIndex) {
                        ForEach(routeInstruction.indices, id: \.self) { index in
                            Text(routeInstruction[index])
                                .tag(index)
                        }
                    }
                    .onChange(of: selectedTabIndex) { value in
                        print(selectedTabIndex, routeInstruction.count)
                        isCameraFollowing = false
                        if !cameraButtonPressed{
                            if selectedTabIndex == routeInstruction.count - 1{
                                withAnimation(.linear(duration: 0.5)) {
                                    vm.navigationCameraTimer?.invalidate()
                                    vm.cameraPosition = .camera(MapCamera(
                                        centerCoordinate: destination ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                        distance: 1000,
                                        heading: 0,
                                        pitch: 60
                                    ))
                                }
                            }else{
                                withAnimation(.linear(duration: 0.5)) {
                                    let loc1 = CLLocationCoordinate2D(latitude: route?.steps[selectedTabIndex+1].polyline.coordinate.latitude ?? 0, longitude: route?.steps[selectedTabIndex+1].polyline.coordinate.longitude ?? 0)
                                    let loc2 = CLLocationCoordinate2D(latitude: route?.steps[selectedTabIndex+2].polyline.coordinate.latitude ?? 0, longitude: route?.steps[selectedTabIndex+2].polyline.coordinate.longitude ?? 0)
                                    vm.navigationCameraTimer?.invalidate()
                                    vm.cameraPosition = .camera(MapCamera(
                                        centerCoordinate: route?.steps[selectedTabIndex+1].polyline.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                        distance: 1000,
                                        heading: calculateHeading(from: loc1, to: loc2),
                                        pitch: 60
                                    ))
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .background(.red)
                    .frame(height: 100)
                }
                Text("Speed: \(locationManager.speed ?? "0")")
                Text(locationManager.isDriving ? "Driving" : "Not Driving")
                Text("Heading: \(locationManager.heading)")

                Spacer()
                
                if !isNavigating{
                    Button("Start Navigation"){
                        withAnimation(.smooth) {
                            startNavigate()
                        }
                    }
                }
                
                if isNavigating{
                    HStack(){
                        Button {
                            cameraButtonPressed = true
                            if isCameraFollowing{
                                withAnimation(.smooth) {
                                    moveCameratoUser()
                                }
                            }else{
                                isCameraFollowing = true
                                withAnimation(.smooth) {
                                    moveCameratoUser()
                                }
                                selectedTabIndex = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                cameraButtonPressed = false
                            }
                        } label: {
                            Image(systemName: isCameraFollowing ? "location.fill" : "location")
                                .padding(14)
                                .background(.white.opacity(0.9))
                                .foregroundColor(.blue)
                                .clipShape(.circle)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    .padding(.bottom, 32)
                }
            }
        }
    }
    
    func getDirections(){
        route = nil
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)))
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.335899, longitude: -122.032477)))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.333857, longitude: -122.072524)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        Task{
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
            print(route?.steps[2].polyline.coordinate.latitude)
        }
    }
    
    func startNavigate(){
        isCameraFollowing = true
        withAnimation(.linear) {
            vm.cameraPosition = .camera(MapCamera(
                centerCoordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                distance: 500,
                heading: locationManager.heading,
                pitch: 60
            ))
        }
        isNavigating = true
        vm.isNavigating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            moveCameratoUser()
        }
        print(route?.steps[1].polyline.coordinate)
//        for (index,step) in route!.steps.enumerated() {
//            print(step.distance)
////            routeInstruction.append(step.instructions + " in " + String(roundValue(step.distance)) + " meters")
////            routeInstruction.append(step.instructions + " in " + String(calculateDistance(from: locationManager.location, to: step[index].polyline.coordinate)) + " meters")
//        }
        for index in 0..<route!.steps.count {
            print(route!.steps[index].distance)
            routeInstruction.append(route!.steps[index].instructions + " in " + String(roundValue(calculateDistance(from: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), to: route!.steps[index].polyline.coordinate))) + " meters")
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let distance = roundValue(calculateDistance(from: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), to: route!.steps[selectedTabIndex+1].polyline.coordinate))
            routeInstruction[selectedTabIndex] = route!.steps[selectedTabIndex+1].instructions + " in " + String(distance) + " meters"
            
            if distance <= 20{
                selectedTabIndex += 1
                currentStep += 1
            }
            
//            routeInstruction.append(route!.steps[selectedTabIndex].instructions + " in " + String(roundValue(calculateDistance(from: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), to: route!.steps[selectedTabIndex+1].polyline.coordinate))) + " meters")
        }
        routeInstruction.removeFirst()
        
//        let timer2 = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
//            if  calculateDistance(from: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), to: route!.steps[selectedTabIndex+1].polyline.coordinate)
//        }
    }
    
    func moveCameratoUser(){
        vm.navigationCameraTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            vm.cameraPosition = .camera(MapCamera(
                centerCoordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                distance: 500,
                heading: locationManager.heading,
                pitch: 60
            ))
        }
    }
    
    func calculateHeading(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = sourceCoordinate.latitude.degreesToRadians
        let lon1 = sourceCoordinate.longitude.degreesToRadians
        let lat2 = destinationCoordinate.latitude.degreesToRadians
        let lon2 = destinationCoordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let heading = atan2(y, x)
        
        return heading.radiansToDegrees
    }
    
    func calculateDistance(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> Double {
        let coordinate1 = CLLocation(latitude: sourceCoordinate.latitude, longitude: sourceCoordinate.longitude)
        let coordinate2 = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        let distanceInMeters = coordinate1.distance(from: coordinate2)
        return distanceInMeters
    }
    
    func roundValue(_ value: Double) -> Int {
        if value > 1000 {
            return Int(round(value / 250.0) * 250.0)
        } else if value > 100 {
            return Int(round(value / 50.0) * 50.0)
        } else {
            return Int(round(value))
        }
    }
}

extension Double {
    var degreesToRadians: Double {
        return self * .pi / 180.0
    }
    
    var radiansToDegrees: Double {
        return self * 180.0 / .pi
    }
}

