//
//  Activity.swift
//  NutriNav
//
//  Activity and hobby tracking models
//

import Foundation

struct Activity: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: ActivityType
    var duration: TimeInterval // in seconds
    var caloriesBurned: Double
    var date: Date
    var source: ActivitySource
    
    init(id: UUID = UUID(), name: String, type: ActivityType, duration: TimeInterval, caloriesBurned: Double, date: Date = Date(), source: ActivitySource = .manual) {
        self.id = id
        self.name = name
        self.type = type
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.date = date
        self.source = source
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
    case yoga = "Yoga"
    case gym = "Gym"
    case walking = "Walking"
    case swimming = "Swimming"
    case hiking = "Hiking"
    case dancing = "Dancing"
    
    var emoji: String {
        switch self {
        case .running: return "🏃"
        case .cycling: return "🚴"
        case .yoga: return "🧘"
        case .gym: return "🏋️"
        case .walking: return "🚶"
        case .swimming: return "🏊"
        case .hiking: return "🥾"
        case .dancing: return "💃"
        }
    }
}

enum ActivitySource: String, Codable {
    case healthKit = "HealthKit"
    case appleWatch = "Apple Watch"
    case manual = "Manual"
}

struct Streak: Codable {
    var currentDays: Int
    var lastDate: Date
    
    var isActive: Bool {
        Calendar.current.isDateInToday(lastDate) || Calendar.current.isDate(lastDate, inSameDayAs: Date().addingTimeInterval(-86400))
    }
}

