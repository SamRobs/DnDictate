//
//  HomeView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Hello There Traveler!")
                .font(.largeTitle)
                .padding()
            
            NavigationLink(destination: EntityView()) {
                Text("View Instruments")
                    .padding()
                    .frame(width: 400)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
            NavigationLink(destination: EntityView2()) {
                Text("View Entities")
                    .padding()
                    .frame(width: 400)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
        }
    }
}
#Preview {
        HomeView()
    }

