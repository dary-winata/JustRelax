//
//  ContentView.swift
//  JustRelax Watch App
//
//  Created by dary winata nugraha djati on 04/05/23.
//

import SwiftUI
import HealthKit
import WatchKit
import UserNotifications

struct HomeView: View {
    @EnvironmentObject var scheduleManager : ScheduleManager
//    @State var currentUUID
    @Environment(\.scenePhase) var scenePhase
    private var healthStore = HKHealthStore()
    @State var workoutSession  : HKWorkoutSession?
    @State var bpmRate : Int?
    @State var startDate : Date?
    @State var notOkay : Bool = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: BreathingView()) {
                    Text("Mulai Pernafasan")
                }
            }
        }.onAppear {
            authorizeNotif()
            scheduleManager.requestAuthorize()
        }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)) { _ in
            print("ini di background")
            notifSchedule()
            scheduleManager.startWorkout()
        }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
            print("ini di foreground")
            scheduleManager.endWorkout()
            startHeartRateQuery(quantityTypeIdentifier: .heartRate)
        }
    }
    
    private func schedulerTesting() {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        
        do {
            self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create workout session: \(error.localizedDescription)")
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
    
    private func authorizeNotif() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { (success, error) in
            if success{
                print("All set")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func runNotif() {
        let userNotificationCenter = UNUserNotificationCenter.current()
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title  = "title"
        notificationContent.body = "body"
        notificationContent.categoryIdentifier = "categoryNameDummy"

        let category = UNNotificationCategory(identifier: "categoryNameDummy", actions: [], intentIdentifiers: [] as? [String] ?? [String](), options: .customDismissAction)
        let categories = Set<AnyHashable>([category])

        userNotificationCenter.setNotificationCategories(categories as? Set<UNNotificationCategory> ?? Set<UNNotificationCategory>())

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                debugPrint(error)
            }
        }
    }
    
    func authorizeHealthKit() {
        let healthKitTypes : Set = [
            HKQuantityType(HKQuantityTypeIdentifier.heartRate)
        ]
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in}
    }
    
    func startHeartRateQuery(quantityTypeIdentifier : HKQuantityTypeIdentifier) {
        print("ini diluar schedule")
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
    
    private func process(samples : [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        let heartRateQuantity = HKUnit(from: "count/min")
        
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
            self.scheduleManager.bpm = Int(lastHeartRate)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
