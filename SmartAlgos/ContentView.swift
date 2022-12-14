//
//  ContentView.swift
//  SmartAlgos
//
//  Created by paco on 01/09/22.
//

import SwiftUI

struct ContentView: View {
    
    
    @StateObject var game = GameModel(size: 38)
    var body: some View {
        
        
        VStack {
            
            Spacer()
            Text(game.state.rawValue)
    
        Grid {
            ForEach(0..<38) { i in
                
                GridRow {
                    ForEach(0..<38) { j in
                        SlotView(slot: game.grid[i][j], playerState: game.playerState)
                    }
                }
            }
        }
            VStack(alignment: .leading) {
                
                VStack {
                  
                    
                    if !game.informed {
                        Toggle("breath first", isOn: $game.breathFirst)
                    }
                    Toggle("Informed Search", isOn: $game.informed)

                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 20) {
                    Button("generate walls") {
                        game.removeWalls()
                        game.generateWalls()
                    }
                    
                    
                    Button("generate flag") {
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
                        game.markPath()
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
            return .black
        case .path:
            return .white.opacity(0.8)
        case .flag:
            return .pink
        }
    }

    
    var body: some View {
        ZStack {
            if slot.state == .visited {
                Color.white
                    .overlay {
                        Color.green.opacity(0.6)
                    }
            } else {
                content
            }
          
//            if slot.state == .flag {
//                Image(systemName: "flag")
//            }
        }

        .frame(width: 10, height: 10)
        .padding(-4)
//        .animation(.spring(), value: slot)
    }
}
