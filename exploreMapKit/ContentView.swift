//
//  ContentView.swift
//  exploreMapKit
//
//  Created by Adry Mirza on 24/10/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @ObservedObject var locationManager = LocationManager()
    @State private var routes: [MKRoute]?
    @State private var selectedResult: MKMapItem?
    @Namespace var mapScope
    @State private var isShowingSheet = false
    @State var mapStyle: MapStyle = .standard(elevation: .realistic, showsTraffic: true)
    @State private var isStandard = true
    
    var body: some View {
        ZStack{
            Map(position: $cameraPosition, scope: mapScope){
                if let routes {
                    ForEach(routes, id: \.self) { route in
                        MapPolyline(route)
                            .stroke(.yellow, lineWidth: 5)
                    }
                }
                Annotation("My Location", coordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                    ZStack {
                        Circle()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.blue.opacity(0.25))
                        Circle()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.white)
                        Circle()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.blue)
                    }
                }.annotationTitles(.hidden)
            }
            .overlay(alignment: .bottomLeading) {
                VStack{
                    MapPitchToggle(scope: mapScope)
                    Button {
                        isShowingSheet.toggle()
                    } label: {
                        Image(systemName: "map")
                            .padding(14)
                            .background(.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .clipShape(.circle)
                    }
                    .sheet(isPresented: $isShowingSheet, content:{
                        VStack(){
                            HStack{
                                Text("Choose map")
                                    .font(.system(size: 24, weight: .semibold))
                                Spacer()
                                Button {
                                    isShowingSheet.toggle()
                                } label: {
                                    Image(systemName: "x.circle.fill")
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.bottom, 28)
                            
                            HStack{
                                Spacer()
                                Button{
                                    mapStyle = .standard(elevation: .realistic, showsTraffic: true)
                                    isStandard = true
                                }label: {
                                    VStack{
                                        Image("2d")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .overlay {
                                                if isStandard {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(.blue, lineWidth: 2)
                                                }
                                            }
                                        
                                        Text("2D")
                                            .font(.system(size: 14, weight: .light))
                                            .padding(.top, 4)
                                            .foregroundStyle(.black)
                                    }
                                }
                                Spacer()
                                Button{
                                    mapStyle = .hybrid(elevation: .realistic, showsTraffic: true)
                                    isStandard = false
                                }label: {
                                    VStack{
                                        Image("hybrid")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(12)
                                            .overlay {
                                                if !isStandard {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(.blue, lineWidth: 2)
                                                }
                                            }

                                        
                                        Text("Satellite")
                                            .font(.system(size: 14, weight: .light))
                                            .padding(.top, 4)
                                            .foregroundStyle(.black)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .presentationDetents([.height(221)])
                        
                        .padding(.horizontal, 24)
                    })
                    
                    MapUserLocationButton(scope: mapScope)
                }
                .padding(.leading, 12)
                .padding(.bottom, 32)
                .buttonBorderShape(.circle)
            }
            .mapStyle(mapStyle)
            .mapScope(mapScope)
            .onAppear(){
                getDirections()
            }
        }
        
        VStack (alignment: .leading){
            HStack{
                Text("Estimate arive to Jembatan Barelang")
                    .font(.system(size: 14))
                    .kerning(-1)
                Spacer()
                Button{
//                    isShowingSheet.toggle()
                }label:{
                    Image(systemName: "chevron.up")
                        .foregroundColor(.black)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 0.5)
            Text("11.30 AM")
                .font(.system(size: 24, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 122)
        .background(Color.white)
    }
    
    func getDirections(){
        routes = nil
        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location ?? CLLocationCoordinate2D(latitude: 3.593655, longitude: 98.666529)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 1.005519, longitude: 104.023670)))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        Task{
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            routes = response?.routes
            print(routes)
            withAnimation(.snappy(duration: 2.0)){
                cameraPosition = .automatic
//                cameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: routes?.first?.polyline.coordinate ?? locationManager.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
            }
        }
    }
    
    func cameraMoveToRoute() -> MapCameraPosition{
        let addonSize = 2 * (Int((routes?.first?.polyline.boundingMapRect.size.height)!) + Int((routes?.first?.polyline.boundingMapRect.size.width)!)) / 9
        
        return MapCameraPosition.rect(MKMapRect(origin: MKMapPoint(x: (routes?.first?.polyline.boundingMapRect.origin.x)!  - (routes?.first?.polyline.boundingMapRect.size.width)!/7, y: (routes?.first?.polyline.boundingMapRect.origin.y)! - (routes?.first?.polyline.boundingMapRect.size.height)!/5), size: MKMapSize(width: (routes?.first?.polyline.boundingMapRect.size.width)! + Double(addonSize), height: (routes?.first?.polyline.boundingMapRect.size.height)! + Double(addonSize))))
    }
}

#Preview {
    ContentView()
}
