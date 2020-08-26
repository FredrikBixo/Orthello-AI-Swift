//
//  ViewController.swift
//  Orthello_AI
//
//  Created by Fredrik Bixo on 2020-07-19.
//  Copyright © 2020 Fredrik Bixo. All rights reserved.
//

import UIKit

/*
 Play a full game, from the beginning to an end, against a human opponent;
 It should be able to play as either the dark or the white player (selectable option before the actual game begins);
 In every game situation suggest a legal move, or admit there is no such move. When the game is finished, it should announce the result and gracefully exit;
 Implement at least the classical mini-max adversarial search algorithm, with the alpha-beta pruning introduced;
 Provide a response within a given, user-predefinable time limit;
 Run on the LTH student Linux system, e.g., on the machine login.student.lth.se (it will be tested there). Any exceptions to this need to be agreed upon in advance!
 */

class ViewController: UIViewController {
    
    let circleRadius:CGFloat = 10;
    @IBOutlet weak var outcome: UILabel!
    
    
    enum Player {
        case white, black;
    }
    
    var move_inprogress = false
    
    var player_turn = Player.black
    
    var opponent = Player.white;
    var me = Player.black;
    
    struct Move {
        var valid:Bool = true;
        var directions:[String] = [];
        var pieces_changed:Int = 0;
        var new_board:[[Int]]?
        var position:(y:Int,x:Int)?
    }
    
    let time_limit_for_search:Double = 4;
    let DEPTH:Int = 6;
    
    var board = Array(repeating: Array(repeating: -1, count: 8), count: 8)
    let boardView = UIView(frame: CGRect(x: 10, y: 10, width: 8*20, height: 8*20))
     
    var no_move_count = 0;
    
    var suggested_move_layer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if me == .black {
            opponent = .white
        } else {
            opponent = .black
        }
        
        boardView.backgroundColor = UIColor.lightGray
        boardView.center = self.view.center
        
        self.view.addSubview(boardView)
        
        self.boardView.layer.addSublayer(suggested_move_layer);
        
        board[3][3] = 0
        board[4][3] = 1
        board[3][4] = 1
        board[4][4] = 0
        
        display_board(board: board)
        
        self.view.backgroundColor = .gray
        
    }
    
    func gameEnded() {
        var sum_whites = 0
        var sum_blacks = 0
        
        for row in board {
            for brick in row {
                if brick == 1 {
                    sum_blacks += 1
                }
                if brick == 0 {
                    sum_whites += 1
                }
            }
        }
        
        if sum_blacks > sum_whites {
            print("Black wins!")
            outcome.text = "Black wins!"
        } else if (sum_blacks == sum_whites) {
            print("Draw")
            outcome.text = "Draw"
        } else {
            print("White wins!")
            outcome.text = "White wins!"
        }
        
    }
    
    func display_board(board:[[Int]]) {
        var y = 0;
        for row in board {
            var x = 0;
            for brick in row {
                
                if brick == 1 {
                    drawCircleAtPos(x: CGFloat(10+20*x), y: CGFloat(10+20*y),player: .black)
                    
                }
                if brick == 0 {
                    drawCircleAtPos(x: CGFloat(10+20*x), y: CGFloat(10+20*y),player: .white)
                }
                
                x += 1;
            }
            
            y += 1;
        }
        
    }
    
    func perform_move(position:(y:Int,x:Int), player:Player, board:[[Int]]) -> Move? {
        
        if position.x > 7 || position.x < 0 || position.y < 0 || position.y > 7 {
            return nil
        }
        
        if board[position.x][position.y] == 1 || board[position.x][position.y] == 0 {
            return nil;
        }
        
        let player_type = player == .black
        
        var new_board = board
        
        var move = Move()
        // check horizontal right
        var valid_move = false
        
        if position.x != 7 {
            if board[position.x+1][position.y] == Int(!player_type as NSNumber) {
                var i1 = position.x
                while(i1 < 6) {
                    i1 = i1 + 1;
                    if (board[i1][position.y] == -1) {
                        break;
                    }
                    if (board[i1][position.y] == Int(!player_type as NSNumber) && board[i1+1][position.y] == Int(player_type as NSNumber)) {
                        valid_move = true
                        while(i1 >= position.x) {
                            new_board[i1][position.y] = Int(player_type as NSNumber)
                            i1 = i1-1;
                        }
                        break;
                    }
                }
            }
        }
      
        
        // check left horizontal
        var i2 = position.x
        if position.x != 0 {
            if board[position.x-1][position.y] == Int(!player_type as NSNumber) {
                while(i2 > 1) {
                    i2 = i2 - 1;
                    if (board[i2][position.y] == -1) {
                        break;
                    }
                    if (board[i2][position.y] == Int(!player_type as NSNumber) && board[i2-1][position.y] == Int(player_type as NSNumber)) {
                        valid_move = true
                        while(i2 <= position.x) {
                            new_board[i2][position.y] = Int(player_type as NSNumber)
                            i2 = i2+1;
                        }
                        break;
                    }
                }
            }
        }
        
        // check diagonal right
        var i3x = position.x
        var i3y = position.y
        
        if position.x != 0 && position.y != 0 {
            
            if board[position.x-1][position.y-1] == Int(!player_type as NSNumber) {
                while(i3x > 1 && i3y > 1) {
                    i3x = i3x - 1;
                    i3y = i3y - 1;
                    if (board[i3x][i3y] == -1) {
                        break;
                    }
                    if (board[i3x][i3y] == Int(!player_type as NSNumber) && board[i3x-1][i3y-1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i3x <= position.x && i3y <= position.y) {
                            new_board[i3x][i3y] = Int(player_type as NSNumber)
                            i3x = i3x + 1;
                            i3y = i3y + 1;
                        }
                        break;
                    }
                }
            }
        }
        
        
        // check diagonal right
        var i4x = position.x
        var i4y = position.y
        if position.x != 7 && position.y != 7 {
            if board[position.x+1][position.y+1] == Int(!player_type as NSNumber) {
                while(i4x < 6 && i4y < 6) {
                    i4x = i4x + 1;
                    i4y = i4y + 1;
                    if (board[i4x][i4y] == -1) {
                        break;
                    }
                    if (board[i4x][i4y] == Int(!player_type as NSNumber) && board[i4x+1][i4y+1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i4x >= position.x && i4y >= position.y) {
                            new_board[i4x][i4y] = Int(player_type as NSNumber)
                            i4x = i4x - 1;
                            i4y = i4y - 1;
                        }
                        break;
                    }
                }
            }
        }
        
        // check diagonal right
        var i7x = position.x
        var i7y = position.y
        
        if position.x != 0 && position.y != 7 {
            if board[position.x-1][position.y+1] == Int(!player_type as NSNumber) {
                while(i7x > 1 && i7y < 6) {
                    i7x = i7x - 1;
                    i7y = i7y + 1;
                    if (board[i7x][i7y] == -1) {
                        break;
                    }
                    if (board[i7x][i7y] == Int(!player_type as NSNumber) && board[i7x-1][i7y+1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i7x <= position.x && i7y >= position.y) {
                            new_board[i7x][i7y] = Int(player_type as NSNumber)
                            i7x = i7x + 1;
                            i7y = i7y - 1;
                        }
                        break;
                    }
                }
            }
        }
        
        
        // check diagonal right
        var i8x = position.x
        var i8y = position.y
        
        if position.x != 7 && position.y != 0 {
            if board[position.x+1][position.y-1] == Int(!player_type as NSNumber) {
                
                while(i8x < 6 && i8y > 1) {
                    i8x = i8x + 1;
                    i8y = i8y - 1;
                    if (board[i8x][i8y] == -1) {
                            break;
                    }
                    if (board[i8x][i8y] == Int(!player_type as NSNumber) && board[i8x+1][i8y-1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i8x >= position.x && i8y <= position.y) {
                            new_board[i8x][i8y] = Int(player_type as NSNumber)
                            i8x = i8x - 1;
                            i8y = i8y + 1;
                        }
                        break;
                    }
                }
            }
        }
        
        // check right verical
        var i5 = position.y
        
        if position.y != 7 {
            if board[position.x][position.y+1] == Int(!player_type as NSNumber) {
                while(i5 < 6) {
                    i5 = i5 + 1;
                    if (board[position.x][i5] == -1) {
                            break;
                    }
                    if (board[position.x][i5] == Int(!player_type as NSNumber) && board[position.x][i5+1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i5 >= position.y) {
                            new_board[position.x][i5] = Int(player_type as NSNumber)
                            i5 = i5-1;
                        }
                        break;
                    }
                }
            }
        }
        
        // check left vertical
        var i6 = position.y
        
        if position.y != 0{
            if board[position.x][position.y-1] == Int(!player_type as NSNumber) {
                while(i6 > 1) {
                    i6 = i6 - 1;
                    if (board[position.x][i6] == -1) {
                      break;
                   }
                    if (board[position.x][i6] == Int(!player_type as NSNumber) && board[position.x][i6-1] == Int(player_type as NSNumber)) {
                        // Backtrack
                        valid_move = true
                        while(i6 <= position.y) {
                            new_board[position.x][i6] = Int(player_type as NSNumber)
                            i6 = i6+1;
                        }
                        break;
                    }
                }
            }
        }
        
        
        if !valid_move {
            return nil;
        }
        
        move.new_board = new_board
        
        return move;
    }
    
    func get_possible_moves(player:Player, board: [[Int]]) -> [Move]{
        
        var valid_moves = Array<Move>();
        for x in 0...7 {
            for y in 0...7 {
                var move = perform_move(position: (x,y),player: player,board: board)
                if move != nil {
                    move?.position = (x,y);
                    valid_moves.append(move!)
                }
            }
        }
        
        return valid_moves
    }
    
    var time:TimeInterval = 0;
    var maxTime:TimeInterval = 0;
    
    func get_best_move() ->  Move? {
        // construct the search tree
        // compute the optimal value for the search
        // use min max to compute the optimal move
        
        let moves = get_possible_moves(player: player_turn, board: board)
        
        if moves.count == 0 {
            print("No possible moves, game finished")
            return nil
        }
        
        var max_move:Float = -100000000.0;
        var bestMove:Move?
        maxTime = time_limit_for_search/Double(moves.count)
        
        for move in moves {
            time = Date().timeIntervalSince1970
            let value = minimax(depth: DEPTH, player: .black, alpha: -1000, beta: 1000, move: move)
            if (value > max_move) {
                max_move = value;
                bestMove = move;
            }
        }
        
        print(max_move)
        
        return bestMove
    }
    
    func evalution_function(move:Move, player:Player, moveCount:Int) -> Float {
        // Use same score
        
        // Example of what to use:
        // Number of white-black peices
        // Number of moves available
        // Number of white/black pieces after applying the move.
        var sum_whites = 0
        var sum_blacks = 0
        
        for row in move.new_board! {
            for brick in row {
                if brick == 1 {
                    sum_blacks += 1
                }
                if brick == 0 {
                    sum_whites += 1
                }
            }
        }
        
        let a:Float = 0.5
        
        var p_moves = Float(moveCount)/64
        
        let token_advantage = Float(sum_blacks-sum_whites)/Float(sum_whites+sum_blacks)
        
        var corner_bonus:Float = 0.0
                   
       if move.new_board![0][0] == 1 {
           corner_bonus += 0.25;
       } else if(move.new_board![0][0] == 0) {
           corner_bonus -= 0.25;
       }
       
       if move.new_board![7][7] == 1 {
           corner_bonus += 0.25;
       } else if(move.new_board![7][7] == 0) {
           corner_bonus -= 0.25;
       }
       
       if move.new_board![0][7] == 1 {
           corner_bonus += 0.25;
       } else if(move.new_board![0][7] == 0) {
           corner_bonus -= 0.25;
       }
       
       if move.new_board![7][0] == 1 {
           corner_bonus += 0.25;
       } else if(move.new_board![7][0] == 0) {
           corner_bonus -= 0.25;
       }
        
        if opponent == .black {
            
            if player == .white {
                p_moves = -p_moves
            }
            return corner_bonus + p_moves*2 + token_advantage
        }
        
        if player == .black {
            p_moves = -p_moves
        }
        return -corner_bonus + p_moves*2 - token_advantage
    }
    
    func minimax(depth:Int, player:Player, alpha:Float, beta:Float, move:Move) -> Float {
        
        var player = player
        
        var alpha = alpha
        var beta = beta
        
        let moves = get_possible_moves(player: player, board: move.new_board!)
        
        if depth == 0 || Date().timeIntervalSince1970-time > maxTime {

            return evalution_function(move: move, player: player, moveCount: moves.count)
        }
        
        if moves.isEmpty {
            if player == .white {
                player = .black
            } else {
                player = .white
            }
            
            return minimax(depth: depth - 1, player: player, alpha: alpha, beta:beta, move: move)
            
        }
        
        
        
        if player == .white {
            var value:Float = -10000000.0
            for move in moves {
                
                value = max(value, minimax(depth: depth - 1, player: .black, alpha: alpha, beta:beta, move: move))
                alpha = max(alpha, value)
                if alpha >= beta {
                    break
                }
            }
            
            return value
        } else {
            // minimizing player
            var value:Float = 10000000.0
            for move in moves {
                value = min(value, minimax(depth: depth - 1, player: .white,alpha: alpha, beta:beta, move: move))
                beta = min(beta, value)
                if alpha >= beta {
                    break
                }
            }
            return value
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first?.location(in: boardView)
        if let location = location {
            
            if player_turn == me {
                
                if get_possible_moves(player: me, board: board).count == 0 {
                    player_turn = opponent
                    return
                }
                
        
                let x_pos = Int(location.x/(circleRadius*2))
                let y_pos = Int(location.y/(circleRadius*2))
                
                
                // I make turn
                let move = perform_move(position:(x_pos,y_pos), player: player_turn, board: board)
                
                
                if move == nil {
                    return;
                }
                
                display_board(board: move!.new_board!)
                
                self.board = move!.new_board!
                
                player_turn = opponent
                
                if get_possible_moves(player: opponent, board: board).count == 0 && get_possible_moves(player: me, board: board).count == 0 {
                    gameEnded()
                    return;
                }
                

            suggested_move_layer.sublayers = nil
                
            } else if player_turn == opponent {
                // Opponents move
                // Get opponents moves
                if get_possible_moves(player: me, board: board).count == 0 {
                        player_turn = me
                       return
                }
                
                let bestMove = get_best_move()
                
                if bestMove == nil {
                    return;
                }

                self.display_board(board: bestMove!.new_board!)
                
                self.board = bestMove!.new_board!
                
                
                // Next guys turn
                player_turn = me
                
                let possible_moves = get_possible_moves(player: me, board: self.board)
                
                if get_possible_moves(player: opponent, board: board).count == 0 && possible_moves.count == 0 {
                    gameEnded()
                    return;
                }
                
                for move in possible_moves {
                    drawSuggestedCircleAtPos(x: circleRadius+CGFloat(move.position!.y)*(circleRadius*2),y: CGFloat(move.position!.x)*(circleRadius*2)+circleRadius)
                    
                }
                
            }
            
        }
    }
    
    func drawSuggestedCircleAtPos(x:CGFloat,y:CGFloat) {
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius:circleRadius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        // Change the fill color
        shapeLayer.fillColor = UIColor.red.cgColor
        
        // You can change the stroke color
        // You can change the line width
        shapeLayer.lineWidth = 3.0
        
        suggested_move_layer.addSublayer(shapeLayer)
    }
    
    func drawCircleAtPos(x:CGFloat,y:CGFloat, player:Player) {
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius:circleRadius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        // Change the fill color
        if player == .black {
            shapeLayer.fillColor = UIColor.black.cgColor
        } else {
            shapeLayer.fillColor = UIColor.white.cgColor
        }
        
        // You can change the stroke color
        // You can change the line width
        shapeLayer.lineWidth = 3.0
        
        boardView.layer.addSublayer(shapeLayer)
    }
    
    
    
}

