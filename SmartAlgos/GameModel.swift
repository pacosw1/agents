//
//  GameModel.swift
//  SmartAlgos
//
//  Created by paco on 01/09/22.
//

import Foundation

enum SlotType: Int {
    case wall = -1
    case player = 0
    case path = 1
    case flag = 2
    case scanning = 3
    case visited = 4
}

enum GameState: String {
    case awaitingInput = "Fill in this shit"
    case initializing = "Intializing Game Board"
    case generatingWalls = "Generating walls"
    case placingFlag = "Placing victory flag"
    case found = "Flag reached"
    case unreachable = "No possible path to flag"
}


struct GridSlot: Identifiable, Hashable {
    var id: UUID = UUID()
    var state: SlotType
    var icon: String = ""
}

struct GridItem {
    var i: Int
    var j: Int
}


let scanIcon = "wifi"
let moveIcon = "arrowshape.turn.up.forward.circle.fill"
let visitIcon = "checkmark.circle.fill"
let checkIcon = "eye.circle.fill"



enum PlayerState: String {
    case moving = "Moving to next scanned value"
    case scanning = "Scanning nearby paths"
    case markVisited = "Marking path as visited"
    case checkForFlag = "Checking for flag"
    case done = "Done"
}

class GameModel: ObservableObject {
    var running: Bool = false
    @Published var state: GameState = .initializing
    @Published var breathFirst: Bool = true
    @Published var size: Int = 5
    @Published var grid: [[GridSlot]] = []
    @Published var loading: Bool = false
    @Published var lastUpdate: Int64 = Date.now.timestamp()
    @Published var agentLocation = GridItem(i: 0, j: 0)
    
    var scanIndex = 0
    
    var playerState: PlayerState = .moving
    
    
    var queue: [GridItem] = []
    
    var walls: Int = 5
    
    func initialize() {
        self.state = .initializing
        self.state = .generatingWalls
        
        self.placeFlag()
//        self.print()
    }
    
    
    func makeMove() -> Bool {
        if !running {
            return true
        }
        switch playerState {
        case .done:
            return true
        case .moving:
            self.movePlayer()
        case .scanning:
            self.scanPaths()
        case .markVisited:
            self.markVisited()
        case .checkForFlag:
            self.checkForFlag()
        }
        
        return false
    }
    
    
    func start() {
        self.running = true
        queue.append(self.agentLocation)
        self.lastUpdate = Date.now.timestamp()
    }
    
    func clearIcons() {
        for i in 0..<size {
            for j in 0..<size {
                grid[i][j].icon = ""
            }
        }
    }
    

    
    func movePlayer() {
        if queue.isEmpty {
            playerState = .done
            return
        }
        
        if self.breathFirst {
            agentLocation = queue.removeFirst()
        } else {
            agentLocation = queue.popLast()!
        }
        
        self.updateSlot(state: .player, i: agentLocation.i, j: agentLocation.j)
        
        playerState = .checkForFlag
    }
    
    
    func updateIcon(icon: String, i: Int, j: Int) {
        grid[i][j].icon = icon
    }
    
    func checkForFlag() {
        var slot = currentSlot()
        slot.icon = checkIcon
        

        // check if we found objective
        if slot.state == .flag {
            state = .found
            updateSlot(state: .player, i: agentLocation.i, j: agentLocation.j)
            return
        }
        
        playerState = .markVisited
    }
    
    func markVisited() {
        var slot = currentSlot()

        if slot.state != .wall {
            // if not mark it as explored
            grid[agentLocation.i][agentLocation.j].state = .visited
            slot.icon = visitIcon

        }
        
        playerState = .scanning
    }
    
    
    func scanPaths() {
//        let i = agentLocation.i
//        let j = agentLocation.j
//
//        let possiblePaths = [
//            GridItem(i: i - 1, j: j), // top
//            GridItem(i: i - 1, j: j - 1), // top left diagonal
//            GridItem(i: i, j: j - 1), // left
//            GridItem(i: i + 1, j: j - 1), // bot left diagonal
//            GridItem(i: i + 1, j: j), // bot
//            GridItem(i: i + 1, j: j + 1), // bot right diagonal
//            GridItem(i: i, j: j + 1), // right
//            GridItem(i: i - 1, j: j + 1) // top right diagonal
//        ]
//
//        let neighbor = possiblePaths[self.scanIndex]
//
//        // check if not in a corner with invalid indexes, or a wall
//        if !isValidIndex(i: neighbor.i, j: neighbor.j) {
//            scanIndex += 1
//            return
//        }
//
//        let slot = grid[neighbor.i][neighbor.j]
//
//        if slot.state == .wall || slot.state == .visited {
//            scanIndex += 1
//            return
//        }
//
//        queue.append(neighbor)
//
//        self.updateSlot(state: .scanning, i: neighbor.i, j: neighbor.j)
//        scanIndex += 1
//
//        if scanIndex < possiblePaths.count {
//            playerState = .moving
//            scanIndex = 0
//        }
        
        let i = agentLocation.i
        let j = agentLocation.j
        
        let possiblePaths = [
            GridItem(i: i - 1, j: j), // top
            GridItem(i: i - 1, j: j - 1), // top left diagonal
            GridItem(i: i, j: j - 1), // left
            GridItem(i: i + 1, j: j - 1), // bot left diagonal
            GridItem(i: i + 1, j: j), // bot
            GridItem(i: i + 1, j: j + 1), // bot right diagonal
            GridItem(i: i, j: j + 1), // right
            GridItem(i: i - 1, j: j + 1) // top right diagonal
        ]
        
        for neighbor in possiblePaths {
            // check if not in a corner with invalid indexes, or a wall
            if !isValidIndex(i: neighbor.i, j: neighbor.j) {
                continue
            }
            
            let slot = grid[neighbor.i][neighbor.j]
            
            if slot.state == .wall || slot.state == .visited || slot.state == .scanning {
                continue
            }
            
            if slot.state == .flag {
                self.updateSlot(state: .player, i: neighbor.i, j: neighbor.j)
                
                playerState = .done
                return
            } else {
                self.updateSlot(state: .scanning, i: neighbor.i, j: neighbor.j)
                self.updateIcon(icon: scanIcon, i: neighbor.i, j: neighbor.j)
            }
            
            
            queue.append(neighbor)
        }
        
        playerState = .moving
    }
    
    
    func currentSlot() -> GridSlot {
        return self.grid[agentLocation.i][agentLocation.j]
    }
    
    
    
    func search() {
        queue.append(self.agentLocation)
        
        while (!queue.isEmpty) {
            
            if self.breathFirst {
                agentLocation = queue.removeFirst()
            } else {
                agentLocation = queue.popLast()!
            }
            let slot = self.grid[agentLocation.i][agentLocation.j]
            
            
//            grid[agentLocation.i][agentLocation.j].state = .player
            
            // check if we found objective
            if slot.state == .flag {
                state = .found
                updateSlot(state: .player, i: agentLocation.i, j: agentLocation.j)
                self.running = false
                self.playerState = .done
                return
            }
            
            // add valid children (valid only)
            self.addNeighbors()
            
            if state == .found {
                return
            }
        }
        
        if state != .found {
            state = .unreachable
        }
        
        self.running = false
        self.playerState = .done
        
    }
    

    
    
    func updateSlot(state: SlotType, i: Int, j: Int) {
        grid[i][j].state = state
    }
    
    
    func addNeighbors() {
        let i = agentLocation.i
        let j = agentLocation.j
        
        let possiblePaths = [
            GridItem(i: i - 1, j: j), // top
            GridItem(i: i - 1, j: j - 1), // top left diagonal
            GridItem(i: i, j: j - 1), // left
            GridItem(i: i + 1, j: j - 1), // bot left diagonal
            GridItem(i: i + 1, j: j), // bot
            GridItem(i: i + 1, j: j + 1), // bot right diagonal
            GridItem(i: i, j: j + 1), // right
            GridItem(i: i - 1, j: j + 1) // top right diagonal
        ]
        
        
        for neighbor in possiblePaths {
            // check if not in a corner with invalid indexes, or a wall
            if !isValidIndex(i: neighbor.i, j: neighbor.j) {
                continue
            }
            
            let slot = grid[neighbor.i][neighbor.j]
            
            if slot.state == .wall || slot.state == .visited || slot.state == .scanning {
                continue
            }
            
            if slot.state == .flag {
                self.updateSlot(state: .player, i: neighbor.i, j: neighbor.j)
                state = .found
                self.running = false
                self.playerState = .done
                return
            } else {
                self.updateSlot(state: .visited, i: neighbor.i, j: neighbor.j)
            }
            
            
            queue.append(neighbor)
        }
        
    }
    
    
    func isValidIndex(i: Int, j: Int) -> Bool {
        return i >= 0 && i < size && j >= 0 && j < size
    }
    
    
    init(size: Int) {
        self.walls = (size*size) / 3
        self.size = size
        self.grid = [[GridSlot]](repeating: [GridSlot](repeating: GridSlot(state: .path), count: size), count: size)
        
        self.updateSlot(state: .player, i: 0, j: 0)
        agentLocation = GridItem(i: 0, j: 0)
        self.generateWalls()
        

        
    }
    
    func reset() {
        self.running = false
        self.walls = (size*size) / 3
        self.size = size
        self.grid = [[GridSlot]](repeating: [GridSlot](repeating: GridSlot(state: .path), count: size), count: size)
        
        self.initialize()
        
        self.queue = []
        
        agentLocation = GridItem(i: 0, j: 0)
        self.updateSlot(state: .player, i: 0, j: 0)
        playerState = .moving
        
        self.generateWalls()
        

    }
    
    
    
    func removeFlag() {
        self.remove(value: .flag)
    }
    func removeWalls() {
        self.remove(value: .wall)
    }
    
    func remove(value: SlotType) {
        for i in 0..<self.size {
            for j in 0..<self.size {
                let slot = self.grid[i][j]
                
                if slot.state == value {
                    grid[i][j].state = .path
                }
            }
        }
    }
    
    // Obstacles use -1
    func generateWalls() {
        for _ in 0...self.walls {
            let _ = self.attemptSlotPlacement(value: .wall)
        }
        
        self.state = .placingFlag
    }
    
    func placeFlag() {
        var placed: Bool = false
        var attempts: Int = 0

        while !placed && attempts < 1000  {
            placed = self.attemptSlotPlacement(value: .flag)
            attempts += 1
        }
//        self.state = .awaitingInput
    }
    
    func attemptSlotPlacement(value: SlotType) -> Bool {
        let i = Int.random(in: 0..<self.size)
        let j = Int.random(in: 0..<self.size)
        
        let val = self.grid[i][j].state
        if val != .path {
            return false
        }
        
        self.grid[i][j].state = value
        
        return true
    }
    
    
}