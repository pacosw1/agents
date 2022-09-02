//
//  ContentView.swift
//  SmartAlgos
//
//  Created by paco on 01/09/22.
//

import SwiftUI

struct ContentView: View {
    
    
    @StateObject var game = GameModel(size: 40)
    var body: some View {
        
        
        VStack {
            
            Spacer()
            Text(game.state.rawValue)
    
        Grid {
            ForEach(0..<40) { i in
                
                GridRow {
                    ForEach(0..<40) { j in
                        SlotView(slot: game.grid[i][j], playerState: game.playerState)
                    }
                }
            }
        }
            
            
        
            
            VStack(alignment: .leading) {
                
                HStack {
                  
                    
                    Toggle("breath first", isOn: $game.breathFirst)
                    Spacer()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 20) {
                    Button("generate walls") {
                        game.removeWalls()
                        game.generateWalls()
                    }
                    
                    
                    Button("generate flag") {
                        game.removeFlag()
                        game.placeFlag()
                    }
                }
                Divider()
                HStack {
                    
                    
                    
                    
                   
                    Button("Reset") {
                        game.reset()
                    }
                    Spacer()
                
        
                    
                    Button("Start") {
                        game.start()
                    }
                    
                    Button("Instant Solve") {
                        game.search()
                    }
                }
                .padding(.top, 50)
            }
            .padding()
            
            Spacer()
    }
        
        .timer(lastUpdate: game.lastUpdate, onFire: {
            return game.makeMove()
        })
        
        .task {
            game.initialize()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}






struct SlotView: View {
    var slot: GridSlot
    var playerState: PlayerState
    
    private var content: Color {
        switch slot.state {
        case .scanning:
            return .blue.opacity(0.5)
        case .player:
            return .blue
        case .visited:
            return .green
        case .wall:
            return .primary
        case .path:
            return .secondary
        case .flag:
            return .pink
        }
    }

    
    var body: some View {
        ZStack {
           content
//            if slot.state == .flag {
//                Image(systemName: "flag")
//            }
        }

        .frame(width: 10, height: 10)
        .padding(-4)
//        .animation(.spring(), value: slot)
    }
}
