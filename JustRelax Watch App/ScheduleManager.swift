//
//  ScheduleManager.swift
//  JustRelax Watch App
//
//  Created by dary winata nugraha djati on 09/05/23.
//

import Foundation
import HealthKit
import UserNotifications
import SwiftUI

class ScheduleManager : NSObject, ObservableObject, Identifiable {
    
    var selectedWorkout: HKWorkoutActivityType = .running
    
    func requestAuthorize() {
//        // The quantity type to write to the health store.
//        let typesToShare: Set = [
//            HKQuantityType.workoutType()
//        ]
//
//        // The quantity types to read from the health store.
//        let typesToRead: Set = [
//            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
//            HKObjectType.activitySummaryType()
//        ]
//
//        // Request authorization for those quantity types.
//        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
//            // Handle error.
//        }
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }

    var healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    var builderWorkout : HKLiveWorkoutBuilder?
    var startDate: Date?

    func startWorkout() {

        // First, check if the health store is available
//        guard let healthStore = healthStore else { return }

        // Create a new workout session
        print("in start")
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            builderWorkout = workoutSession?.associatedWorkoutBuilder()
        } catch {
            fatalError("Unable to create workout session: \(error.localizedDescription)")
        }
        
        // setup session and builder
        workoutSession?.delegate = self
        builderWorkout?.delegate = self
        // Start the workout session
        
        builderWorkout?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: workoutConfiguration)
        
        // Start the workout session and begin data collection.
        let startDate = Date().addingTimeInterval(10)
        print(startDate)
        workoutSession?.startActivity(with: startDate)
        builderWorkout?.beginCollection(withStart: startDate) { (success, error) in
            
        }
    }
    
    @Published var running = false

    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }
    
    func pause() {
        workoutSession?.pause()
    }

    func resume() {
        workoutSession?.resume()
    }

    func endWorkout() {
        workoutSession?.end()
    }
    
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }
    
    func startHeartRateQuery(quantityTypeIdentifier : HKQuantityTypeIdentifier) {
        print("running")
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler : (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
                        
            self.process(samples: samples, type: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(type: HKQuantityType(quantityTypeIdentifier), predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        healthStore.execute(query)
    }
    
    @Published var bpm : Int = 0
    
    func process(samples : [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        let heartRateQuantity = HKUnit(from: "count/min")
        
        var lastHeartRate = 0.0
                
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
            self.bpm = Int(lastHeartRate)
        }
    }
    
    private func notifSchedule() {
        let content = UNMutableNotificationContent()
        content.title = "Hello"
        content.body = "Are you okay?"
        
        content.sound = UNNotificationSound.default
        
        let startAction = UNNotificationAction(identifier: "start", title: "No", options: [.foreground])
        let dismissAction = UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [.destructive])
//        let isStressed = UNNotificationAction(identifier: "Yes", title: "")
        let category = UNNotificationCategory(identifier: "notification", actions: [startAction, dismissAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "notification"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        let request = UNNotificationRequest(identifier: "silentNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule silent notification: \(error)")
            } else {
                print("Silent notification scheduled successfully")
            }
        }
    }
}

extension ScheduleManager : HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
//        for type in collectedTypes {
//            guard let quantityType = type as? HKQuantityType else {
//                return
//            }

        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
        if bpm >= 80 {
            notifSchedule()
        }
//        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
}

extension ScheduleManager : HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builderWorkout?.endCollection(withEnd: date) { (success, error) in
                self.builderWorkout?.finishWorkout { (workout, error) in
                }
            }
        }
    }
}
