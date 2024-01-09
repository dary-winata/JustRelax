//
//  BreathingView.swift
//  JustRelax Watch App
//
//  Created by dary winata nugraha djati on 11/05/23.
//

import SwiftUI
import WatchKit
import Foundation
import AVKit
import AVFoundation

struct BreathingView: View {
    @EnvironmentObject var scheduleManager : ScheduleManager
    @State var timePlayState : DispatchTime = .now()
    let videoName : [String] = ["shark_1", "shark_2", "shark_3", "shark_4"]
    @State var layoutTextValue : String = "Mari Mulai"
    @State var isDone : Bool = false
    @State var indexNow : Int = 0
    @State var countDown : Bool = true

    var body: some View {
        if isDone {
            HomeView()
        } else {
            VStack {
                if !countDown {
                    VideoPlayer(player: setVideo())
                }
                Text(layoutTextValue)
            }.onAppear {
                scheduleManager.endWorkout()
                setLastState()
                changeLayout()
            }.onChange(of: layoutTextValue) { _ in
                setLastState()
            }
//            }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)) { _ in
//                scheduleManager.endWorkout()
//            }
        }
    }
    
    private func setVideo() -> AVPlayer {
        let video = Bundle.main.path(forResource: videoName[indexNow], ofType: "mov")!
        let url = URL(fileURLWithPath: video)
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.play()
//        player.
        
        return player
    }
    
    private func changeLayout() {
        let serialQueue = DispatchQueue(label: "bernafas")
        var timePlay : DispatchTime = .now() + 2
        
        serialQueue.asyncAfter(deadline: .now() + 1) {
            layoutTextValue = "3"
        }
        
        serialQueue.asyncAfter(deadline: .now() + 2) {
            layoutTextValue = "2"
        }
        
        serialQueue.asyncAfter(deadline: .now() + 3) {
            layoutTextValue = "1"
        }
        
        for _ in 0...3 {
            timePlay = timePlay + 3
            serialQueue.asyncAfter(deadline: timePlay) {
                countDown = false
                indexNow = 0
                layoutTextValue = "tarik nafas perlahan"
                WKInterfaceDevice().play(.start)
            }
            timePlay = timePlay + 3
            serialQueue.asyncAfter(deadline: timePlay) {
                indexNow = 1
                layoutTextValue = "buang nafas perlahan"
                WKInterfaceDevice().play(.start)
            }
            timePlay = timePlay + 3
            serialQueue.asyncAfter(deadline: timePlay) {
                layoutTextValue = "tahan nafas"
                indexNow = 2
                WKInterfaceDevice().play(.start)
            }
        }
        
        serialQueue.asyncAfter(deadline: timePlay + 3) {
            WKInterfaceDevice().play(.success)
            indexNow = 3
            layoutTextValue = "Selesai"
        }
        
        serialQueue.asyncAfter(deadline: timePlay + 9) {
            isDone = true
        }
    }
    
//    private func newImage() {
//        if indexNow == 2 {
//            indexNow = 0
//        }
//
//        indexNow = indexNow + 1
//    }

    private func setLastState() {
        DispatchQueue.main.asyncAfter(deadline: timePlayState) {
            let activity = NSUserActivity(activityType: "lastStateView")
            activity.userInfo = ["appUrl" : URL(string: "myapp://")!]
            activity.becomeCurrent()
        }
    }
}

struct BreathingView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingView()
    }
}
