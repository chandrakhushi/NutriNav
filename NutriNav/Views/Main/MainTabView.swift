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
            
            NavigationStack {
                LogFoodView()
            }
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
                .tag(TabItem.log)
            
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "mappin.circle.fill")
                }
                .tag(TabItem.nearby)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(TabItem.profile)
        }
        .tint(.primaryAccent)
        .onAppear {
            // Configure tab bar appearance for light/dark mode
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = .clear
            
            // Normal state (inactive)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "9E9E9E")
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "9E9E9E")
            ]
            
            // Selected state (active)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "4CAF50")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "4CAF50")
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
