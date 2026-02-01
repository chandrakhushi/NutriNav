//
//  CyclePredictionService.swift
//  NutriNav
//
//  Automatic menstrual cycle prediction using HealthKit data with manual fallback.
//  Uses medically reasonable phase approximations.
//
//  MEDICAL ASSUMPTIONS (documented):
//  - Average cycle length: 28 days (range: 21-35 considered normal)
//  - Menstrual phase: Days 1-5
//  - Follicular phase: Days 6 to ovulation
//  - Ovulation: ~14 days before next period (±1 day)
//  - Luteal phase: Post-ovulation to next period (~14 days, fairly constant)
//
//  References:
//  - ACOG (American College of OB/GYN) cycle guidelines
//  - NHS menstrual cycle information
//

import Foundation
import HealthKit
import Combine

// MARK: - Cycle Data Model

struct CycleData: Codable, Equatable {
    var lastPeriodStartDate: Date?
    var averageCycleLength: Int // in days, default 28
    var averagePeriodLength: Int // in days, default 5
    var dataSource: CycleDataSource
    var lastUpdated: Date
    
    // Computed properties
    var currentCycleDay: Int? {
        guard let lastPeriod = lastPeriodStartDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPeriod), to: calendar.startOfDay(for: Date())).day ?? 0
        return days + 1 // Day 1 is first day of period
    }
    
    var currentPhase: CyclePhase? {
        guard let cycleDay = currentCycleDay else { return nil }
        return CyclePredictionService.shared.determinePhase(cycleDay: cycleDay, cycleLength: averageCycleLength, periodLength: averagePeriodLength)
    }
    
    var estimatedNextPeriodDate: Date? {
        guard let lastPeriod = lastPeriodStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: averageCycleLength, to: lastPeriod)
    }
    
    var estimatedOvulationDate: Date? {
        guard let nextPeriod = estimatedNextPeriodDate else { return nil }
        // Ovulation typically occurs 14 days before next period (luteal phase is constant)
        return Calendar.current.date(byAdding: .day, value: -14, to: nextPeriod)
    }
    
    var daysUntilNextPeriod: Int? {
        guard let nextPeriod = estimatedNextPeriodDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
        return max(0, days)
    }
    
    // Default initializer
    init(
        lastPeriodStartDate: Date? = nil,
        averageCycleLength: Int = 28,
        averagePeriodLength: Int = 5,
        dataSource: CycleDataSource = .none,
        lastUpdated: Date = Date()
    ) {
        self.lastPeriodStartDate = lastPeriodStartDate
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.dataSource = dataSource
        self.lastUpdated = lastUpdated
    }
}

enum CycleDataSource: String, Codable {
    case healthKit = "Apple Health"
    case manual = "Manual Entry"
    case none = "Not Set"
}

// MARK: - Period Entry (for history tracking)

struct PeriodEntry: Codable, Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let source: CycleDataSource
    
    init(startDate: Date, endDate: Date? = nil, source: CycleDataSource = .manual) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.source = source
    }
    
    var duration: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day
    }
}

// MARK: - Cycle Prediction Service

class CyclePredictionService: ObservableObject {
    static let shared = CyclePredictionService()
    
    private let healthStore = HKHealthStore()
    
    @Published var cycleData: CycleData = CycleData()
    @Published var periodHistory: [PeriodEntry] = []
    @Published var isHealthKitAuthorized: Bool = false
    @Published var hasHealthKitData: Bool = false
    
    private init() {}
    
    // MARK: - Phase Determination Logic
    //
    // Medical basis for phase calculation:
    // - Menstrual: Days 1-5 (bleeding phase)
    // - Follicular: Day 6 to ovulation (estrogen rising)
    // - Ovulation: ~14 days before next period, lasting 1-2 days
    // - Luteal: Post-ovulation to next period (~14 days, most consistent phase)
    //
    // The luteal phase is relatively constant at 14 days (±2 days)
    // Cycle length variation mostly comes from follicular phase
    //
    func determinePhase(cycleDay: Int, cycleLength: Int, periodLength: Int) -> CyclePhase {
        // Ensure valid inputs
        let validCycleLength = max(21, min(45, cycleLength))
        let validPeriodLength = max(3, min(7, periodLength))
        
        // Calculate phase boundaries
        let menstrualEnd = validPeriodLength
        let lutealStart = validCycleLength - 14 // Luteal is ~14 days before next period
        let ovulationStart = lutealStart - 1 // Ovulation is 1-2 days before luteal
        let ovulationEnd = lutealStart
        
        // Determine phase based on cycle day
        if cycleDay <= menstrualEnd {
            return .menstruation
        } else if cycleDay < ovulationStart {
            return .follicular
        } else if cycleDay <= ovulationEnd {
            return .ovulation
        } else {
            return .luteal
        }
    }
    
    // MARK: - HealthKit Integration
    
    /// Check if HealthKit menstrual data is available
    func checkHealthKitAvailability() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard HKCategoryType.categoryType(forIdentifier: .menstrualFlow) != nil else { return false }
        return true
    }
    
    /// Request HealthKit authorization for menstrual data
    func requestHealthKitAuthorization() async throws {
        guard checkHealthKitAvailability() else {
            throw CyclePredictionError.healthKitNotAvailable
        }
        
        var typesToRead: Set<HKObjectType> = []
        
        // Required: Menstrual flow
        if let menstrualType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) {
            typesToRead.insert(menstrualType)
        }
        
        // Optional: Basal body temperature (can indicate ovulation)
        if let bbtType = HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature) {
            typesToRead.insert(bbtType)
        }
        
        // Optional: Ovulation test results
        if let ovulationType = HKCategoryType.categoryType(forIdentifier: .ovulationTestResult) {
            typesToRead.insert(ovulationType)
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.isHealthKitAuthorized = true
            }
        } catch {
            throw CyclePredictionError.authorizationFailed(error)
        }
    }
    
    /// Fetch menstrual flow data from HealthKit
    func fetchHealthKitCycleData() async throws -> CycleData {
        guard let menstrualType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            throw CyclePredictionError.invalidType
        }
        
        // Fetch last 6 months of data for accurate cycle length calculation
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: sixMonthsAgo, end: Date(), options: .strictStartDate)
        
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: CyclePredictionError.queryFailed(error))
                    return
                }
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            healthStore.execute(query)
        }
        
        // Process samples to find period start dates
        let periodStarts = extractPeriodStartDates(from: samples)
        
        guard !periodStarts.isEmpty else {
            await MainActor.run {
                self.hasHealthKitData = false
            }
            throw CyclePredictionError.noData
        }
        
        await MainActor.run {
            self.hasHealthKitData = true
        }
        
        // Calculate average cycle length from history
        let (avgCycleLength, avgPeriodLength) = calculateAverageCycleLengths(from: periodStarts, samples: samples)
        
        // Get most recent period start
        let lastPeriodStart = periodStarts.last!
        
        return CycleData(
            lastPeriodStartDate: lastPeriodStart,
            averageCycleLength: avgCycleLength,
            averagePeriodLength: avgPeriodLength,
            dataSource: .healthKit,
            lastUpdated: Date()
        )
    }
    
    /// Extract period start dates from HealthKit samples
    /// A period start is the first day of menstrual flow after a gap
    private func extractPeriodStartDates(from samples: [HKCategorySample]) -> [Date] {
        let calendar = Calendar.current
        var periodStarts: [Date] = []
        var lastFlowDate: Date?
        
        for sample in samples {
            // Check if this is actual flow (not spotting or none)
            let isFlow = sample.value == HKCategoryValueMenstrualFlow.light.rawValue ||
                         sample.value == HKCategoryValueMenstrualFlow.medium.rawValue ||
                         sample.value == HKCategoryValueMenstrualFlow.heavy.rawValue ||
                         sample.value == HKCategoryValueMenstrualFlow.unspecified.rawValue
            
            guard isFlow else { continue }
            
            let sampleDate = calendar.startOfDay(for: sample.startDate)
            
            if let last = lastFlowDate {
                // If more than 7 days since last flow, this is a new period
                let daysSinceLast = calendar.dateComponents([.day], from: last, to: sampleDate).day ?? 0
                if daysSinceLast > 7 {
                    periodStarts.append(sampleDate)
                }
            } else {
                // First flow sample is a period start
                periodStarts.append(sampleDate)
            }
            
            lastFlowDate = sampleDate
        }
        
        return periodStarts
    }
    
    /// Calculate average cycle and period lengths from history
    private func calculateAverageCycleLengths(from periodStarts: [Date], samples: [HKCategorySample]) -> (Int, Int) {
        var cycleLengths: [Int] = []
        let calendar = Calendar.current
        
        // Calculate cycle lengths between consecutive periods
        for i in 1..<periodStarts.count {
            let days = calendar.dateComponents([.day], from: periodStarts[i-1], to: periodStarts[i]).day ?? 0
            // Only include reasonable cycle lengths (21-45 days)
            if days >= 21 && days <= 45 {
                cycleLengths.append(days)
            }
        }
        
        // Calculate average cycle length
        let avgCycleLength: Int
        if cycleLengths.isEmpty {
            avgCycleLength = 28 // Default
        } else {
            avgCycleLength = cycleLengths.reduce(0, +) / cycleLengths.count
        }
        
        // Estimate average period length (default 5 if can't determine)
        let avgPeriodLength = 5
        
        return (avgCycleLength, avgPeriodLength)
    }
    
    // MARK: - Manual Entry
    
    /// Log a period start date manually
    func logPeriodStart(date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Update cycle data
        cycleData.lastPeriodStartDate = startOfDay
        cycleData.dataSource = .manual
        cycleData.lastUpdated = Date()
        
        // Add to history
        let entry = PeriodEntry(startDate: startOfDay, source: .manual)
        periodHistory.append(entry)
        
        // Recalculate average cycle length if we have history
        if periodHistory.count >= 2 {
            updateAverageCycleLength()
        }
    }
    
    /// Update average cycle length from manual history
    private func updateAverageCycleLength() {
        let sortedHistory = periodHistory.sorted { $0.startDate < $1.startDate }
        var cycleLengths: [Int] = []
        let calendar = Calendar.current
        
        for i in 1..<sortedHistory.count {
            let days = calendar.dateComponents([.day], from: sortedHistory[i-1].startDate, to: sortedHistory[i].startDate).day ?? 0
            if days >= 21 && days <= 45 {
                cycleLengths.append(days)
            }
        }
        
        if !cycleLengths.isEmpty {
            cycleData.averageCycleLength = cycleLengths.reduce(0, +) / cycleLengths.count
        }
    }
    
    // MARK: - Sync & Refresh
    
    /// Sync cycle data from HealthKit or use manual data
    func syncCycleData() async {
        // Try HealthKit first
        if isHealthKitAuthorized {
            do {
                let hkData = try await fetchHealthKitCycleData()
                await MainActor.run {
                    self.cycleData = hkData
                }
                return
            } catch {
                print("HealthKit cycle sync failed: \(error)")
                // Fall through to manual data
            }
        }
        
        // Use existing manual data if available
        if cycleData.dataSource == .manual && cycleData.lastPeriodStartDate != nil {
            await MainActor.run {
                self.cycleData.lastUpdated = Date()
            }
        }
    }
    
    /// Refresh cycle data (call on app launch and when new HK data arrives)
    func refreshCycleData() async {
        // If authorized, try to get fresh HealthKit data
        if isHealthKitAuthorized && hasHealthKitData {
            await syncCycleData()
        }
        // Otherwise, just update the timestamp (phase will recalculate based on date)
        await MainActor.run {
            self.cycleData.lastUpdated = Date()
        }
    }
}

// MARK: - Errors

enum CyclePredictionError: LocalizedError {
    case healthKitNotAvailable
    case authorizationFailed(Error)
    case invalidType
    case queryFailed(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed(let error):
            return "Failed to authorize: \(error.localizedDescription)"
        case .invalidType:
            return "Invalid data type"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        case .noData:
            return "No menstrual cycle data found in Apple Health"
        }
    }
}

