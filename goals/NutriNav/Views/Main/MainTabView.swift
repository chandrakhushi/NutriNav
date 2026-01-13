//
//  MainTabView.swift
//  NutriNav
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(TabItem.home)
            
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(TabItem.recipes)
            
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "mappin.circle.fill")
                }
                .tag(TabItem.nearby)
            
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
                .tag(TabItem.activities)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(TabItem.profile)
        }
        .tint(.appPurple)
    }
}

