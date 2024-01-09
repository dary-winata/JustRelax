////
////  HealthKitController.swift
////  JustRelax Watch App
////
////  Created by dary winata nugraha djati on 08/05/23.
////
//
//import Foundation
//import HealthKit
//
//class HealthKitController {
//    private var healthStore = HKHealthStore()
//    
//    func authorizeHealthKit() {
//        let healthKitTypes : Set = [
//            HKQuantityType(HKQuantityTypeIdentifier.heartRate)
//        ]
//        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in}
//    }
//    
//    func startHeartRateQuery(quantityTypeIdentifier : HKQuantityTypeIdentifier) {
//        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
//        let updateHandler : (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
//            query, samples, deletedObjects, queryAnchor, error in
//            guard let samples = samples as? [HKQuantitySample] else {
//                return
//            }
//            
//            self.process(samples: samples, type: quantityTypeIdentifier)
//        }
//        
//        let query = HKAnchoredObjectQuery(type: HKQuantityType(quantityTypeIdentifier), predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
//        
//        query.updateHandler = updateHandler
//        healthStore.execute(query)
//    }
//    
////    private func process(samples : [HKQuantitySample], type: HKQuantityTypeIdentifier) -> Int {
////        let heartRateQuantity = HKUnit(from: "count/min")
////        
////        var lastHeartRate = 0.0
////        
////        for sample in samples {
////            print("test")
////            if type == .heartRate {
////                print("inside")
////                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
////            }
////            self.bpmRate = Int(lastHeartRate)
////        }
////    }
//}
