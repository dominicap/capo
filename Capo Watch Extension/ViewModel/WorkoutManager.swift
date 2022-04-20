//
//  WorkoutManager.swift
//  Capo Watch Extension
//
//  Created by Dominic Philip on 4/19/22.
//

import CoreMotion
import Foundation
import HealthKit
import os.log

class WorkoutManager: NSObject, ObservableObject {

  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WorkoutManager")

  let healthStore = HKHealthStore()
  let pedometer = CMPedometer()

  var session: HKWorkoutSession?
  var builder: HKLiveWorkoutBuilder?

  @Published var isActive = false

  @Published var cadence = 0

  func requestAuthorization() {
    let workouts: Set = [
      HKQuantityType.workoutType()
    ]

    let stats: Set = [
      HKQuantityType.quantityType(forIdentifier: .heartRate)!,
      HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
      HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
      HKObjectType.activitySummaryType(),
    ]

    healthStore.requestAuthorization(toShare: workouts, read: stats) { success, error in
      // Handle success or error.
    }
  }

  func start() {
    requestAuthorization()

    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    configuration.locationType = .outdoor

    do {
      session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
      builder = session?.associatedWorkoutBuilder()
    } catch {
      return
    }

    builder?.dataSource = HKLiveWorkoutDataSource(
      healthStore: healthStore, workoutConfiguration: configuration)

    session?.delegate = self
    builder?.delegate = self

    let date = Date()
    session?.startActivity(with: date)
    builder?.beginCollection(
      withStart: date,
      completion: { success, error in
        guard error == nil, success == true else {
          return
        }

        if CMPedometer.isCadenceAvailable() {
          self.pedometer.startUpdates(from: date) { data, error in
            guard error == nil, let data = data else {
              return
            }

            if self.isActive {
              DispatchQueue.main.async {
                if let currentCadence = data.currentCadence {
                  self.cadence = Int((currentCadence.doubleValue * 60).rounded())
                } else {
                  self.cadence = 0
                }
              }
            }
          }
        }
      })
  }

  func pause() {
    session?.pause()
  }

  func resume() {
    session?.resume()
  }

  func toggle() {
    if isActive {
      pause()
    } else {
      resume()
    }
  }

  func stop() {
    session?.end()
  }

}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {

  func workoutSession(
    _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
    from fromState: HKWorkoutSessionState, date: Date
  ) {
    DispatchQueue.main.async {
      self.isActive = toState == .running
    }

    if toState == .ended {
      builder?.endCollection(
        withEnd: date,
        completion: { success, error in
          self.builder?.finishWorkout(completion: { workout, error in
            guard error == nil else {
              return
            }

            self.pedometer.stopUpdates()
          })
        })
    }
  }

  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}

}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {

  func workoutBuilder(
    _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>
  ) {

  }

  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

}
