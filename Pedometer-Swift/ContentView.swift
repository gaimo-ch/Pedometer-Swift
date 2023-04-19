//
//  ContentView.swift
//  Pedometer-Swift
//
//  Created by gaimo on 2023/04/19.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthStore = HKHealthStore()
    @State private var stepCount = 0

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.mint, .teal]), startPoint: .top, endPoint: .bottom)
                 .ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: 300, height: 100)
                .opacity(0.6)
                .padding(.bottom, 100)
                HStack {
                    Text("\(stepCount)")
                        .font(.custom("Rounded-X Mgen+ 1c", size: 60))
                        .foregroundColor(.teal)
                        .font(.title)
                        .padding(.bottom, 100)
                    Text(" 歩")
                        .font(.custom("Rounded-X Mgen+ 1c", size: 30))
                        .foregroundColor(.teal)
                        .font(.title)
                        .padding(.bottom, 80)
            }
        }
        .onAppear {
            requestAuthorization()
            startObservingChanges()
        }
    }

    func requestAuthorization() {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [stepCount]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if success {
                getStepCount()
            } else {
                print("Authorization not granted")
            }
        }
    }

    func getStepCount() {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    self.stepCount = stepCount
                }
            }
        }

        healthStore.execute(query)
    }

    func startObservingChanges() {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKObserverQuery(sampleType: stepCount, predicate: predicate) { (query, completionHandler, error) in
            self.getStepCount()
        }

        healthStore.execute(query)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
