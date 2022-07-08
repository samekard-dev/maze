import Foundation

struct Trigger: Hashable {
	let x: Int
	let y: Int
	let v: Int
	let goingX: Int
	let goingY: Int
	let straight: Int
}

var w = 15//奇数であること
var h = 15//奇数であること

guard w >= 7 else {
	fatalError("wが小さすぎます")
}
guard h >= 7 else {
	fatalError("hが小さすぎます")
}

var bestField: [[Int]] = []
var bestValue = -1.0
let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]

func inFiled(x: Int, y: Int, dx: Int, dy: Int) -> Bool {
	if x + dx < 0 || w <= x + dx || y + dy < 0 || h <= y + dy {
		return false
	}
	return true
}

for _ in 1...30 {
	
	bestValue = -1.0
	
	for _ in 1...20 {
		
		/*
		 迷路を作成する
		 */
		
		var field = [[Int]](repeating: [Int](repeating: 0, count: w), count: h)
		//通れない : 0
		//通れる : 1以上
		
		var filled = (h + 1) / 2 * (w + 1) / 2 //通路にすべきところを通路にした回数。減らしていく。
		var triggers: Set<Trigger> = []
		
		func writeField(x: Int, y: Int, value: Int, goingX: Int, goingY: Int, straight: Int) {
			field[y][x] = value
			filled -= 1
			
			if x == w - 1 && y == h - 1 {
				return
			}
			
			triggers.insert(Trigger(x: x, y: y, v: value, 
									goingX: goingX, goingY: goingY, straight: straight))

			toNext(x: x, y: y, value: value, goingX: goingX, goingY: goingY, straight: straight)
		}
		
		func toNext(x: Int, y: Int, value: Int, goingX: Int, goingY: Int, straight: Int) {
			
			let goDirs: [(Int, Int)]
			//x方向y方向のムラが出ないように乱数で
			if Bool.random() {
				goDirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
			} else {
				goDirs = [(0, -1), (0, 1), (-1, 0), (1, 0)]
			}
			for (dx, dy) in goDirs {
				guard inFiled(x: x, y: y, dx: dx, dy: dy) else {
					continue
				}

				let dx2 = 2 * dx
				let dy2 = 2 * dy
				
				guard field[y + dy2][x + dx2] == 0 else {
					//ループができてしまうためやらない
					continue
				}
				
				if dx == goingX && dy == goingY {
					//直線は見てすぐわかるので長くなるのを避ける
					let goStraight = 1.0 / pow(2.0, Double(straight)) //先に進む確率
					guard Double.random(in: 0.0...1.0) < goStraight else {
						continue
					}
				}
				
				let seed = 0.66 //道を開通する確率
				
				guard Double.random(in: 0.0...1.0) < seed else {
					//道を開けるかどうかの決定。
					continue
				}
				
				field[y + dy][x + dx] = value + 1
				var nextStraight = straight + 1
				if dx != goingX || dy != goingY {
					nextStraight = 1
				}
				writeField(x: x + dx2, y: y + dy2, value: value + 2,
					  goingX: dx, goingY: dy, straight: nextStraight)
			}
		}
		
		writeField(x: 0, y: 0, value: 1,
			  goingX: 0, goingY: 0, straight: 0)
		
		while filled > 0 {
			let t = triggers.randomElement()!
			
			var exe = false
			for (dx, dy) in dirs {
				let dx2 = 2 * dx
				let dy2 = 2 * dy
				guard inFiled(x: t.x, y: t.y, dx: dx2, dy: dy2) else {
					continue
				}

				if field[t.y + dy2][t.x + dx2] == 0 {
					exe = true
					break
				}
			}		
			
			if exe {
				toNext(x: t.x, y: t.y, value: t.v,
					 goingX: t.goingX, goingY: t.goingY, straight: t.straight)
			} else {
				triggers.remove(t)
			}
		}
		
		let value = evaluateField(field: field, printOn: false)
		
		if value > bestValue {
			bestValue = value
			bestField = field
		}
	}
	
	_ = evaluateField(field: bestField, printOn: true)
}

func evaluateField(field: [[Int]], printOn: Bool) -> Double {
	
	var answer: [(x: Int, y: Int)] = []
	
	var x = w - 1
	var y = h - 1
	while true {
		answer.append((x: x, y: y))
		if x == 0 && y == 0 {
			break
		}
		for (dy, dx) in dirs {
			guard inFiled(x: x, y: y, dx: dx, dy: dy) else {
				continue
			}
			if field[y + dy][x + dx] == field[y][x] - 1 {
				x = x + dx
				y = y + dy
				break
			}
		}
	}
	
	answer = answer.reversed()
	
	/*
	 迷路を評価する
	 
	 チェック項目
	 - 答の距離
	 - 答の曲がる回数
	 - 不正解ルートの多さ
	 */
	func chechTurn() -> Int {
		var turns = 0
		for pos in stride(from: 1, through: answer.count - 4, by: 2) {
			if abs(answer[pos].x - answer[pos + 2].x) == 2 ||
				abs(answer[pos].y - answer[pos + 2].y) == 2 {
				//まっすぐ
			} else {
				turns += 1
			}
		}
		return turns
	}
	
	func checkChoiceInAnswer() -> Int {
		var choices = 0
		for pos in stride(from: 0, through: answer.count - 3, by: 2) {
			var inChoices = 0
			let x = answer[pos].x
			let y = answer[pos].y
			for (dx, dy) in dirs {
				guard inFiled(x: x, y: y, dx: dx, dy: dy) else {
					continue
				}
				if field[y + dy][x + dx] != 0 {
					inChoices += 1
				}
			}
			if pos == 0 {
				choices += inChoices - 1
			} else {
				choices += inChoices - 2
			}
		}
		return choices
	}
	
	func checkSideRoad(x: Int, y: Int, exclude: [(x: Int, y: Int)]) -> Double {
		
		//枝が生えていたら結果を返す
		//枝が複数なら計算して返す
		var result = 0.0
		var choice: [Double] = []
		
	search:
		for (dx, dy) in dirs {
			for e in exclude {
				if  dx == e.x && dy == e.y {
					continue search
				}
			}
			guard inFiled(x: x, y: y, dx: dx, dy: dy) else {
				continue
			}
			if field[y + dy][x + dx] == 0 {
				continue
			}
			choice.append(checkSideRoad(x: x + dx + dx, 
										y: y + dy + dy, 
										exclude: [(x: -dx, y: -dy)])
						  + 2.0) //2.0はx + dxとx + dx + dxの分
		}
		
		switch choice.count {
			case 0:
				break
			case 1:
				result = choice[0]
			case 2:
				result = (choice[0] + choice[1])
				* pow(choice[0] * choice[1], 1.0 / 8.0)
			case 3:
				result = (choice[0] + choice[1] + choice[2])
				* pow(choice[0] * choice[1] * choice[2], 1.0 / 8.0)
			default:
				break
		}
		return result
	}
	
	func checkSideRoads() -> Double {
		var returnValue = 0.0
		for i in stride(from: 0, through: answer.count - 3, by: 2) {
			let x = answer[i].x
			let y = answer[i].y
			var e: [(x: Int, y: Int)] = []
			if i != 0 {
				e.append((x: answer[i - 1].x - x, y: answer[i - 1].y - y))
			}
			e.append((x: answer[i + 1].x - x, y: answer[i + 1].y - y))
			let value = (checkSideRoad(x: x, y: y, exclude: e))
			* (cos(Double(field[y][x]) / Double(field[h - 1][w - 1]) * Double.pi) + 1.0)
			returnValue += value
			
		}
		return returnValue
	}
	
	/*
	 y = x / (x + 1)
	 */
	
	let answerLength = Double(field[h - 1][w - 1]) / Double(h + w - 1)
	let turnCount = Double(chechTurn()) / Double(h + w - 1)
	let choiceCount = Double(checkChoiceInAnswer()) / Double(h + w - 1)
	
	var valueSouece = [
		[answerLength, 1.1, 1.5, 0.0],
		[turnCount, 0.1, 0.3, 0.0],
		[choiceCount, 0.25, 0.5, 0.0],
	]
	
	var value = 1.0
	for i in 0..<3 {
		var source = 0.0
		let source1 = valueSouece[i][0] - valueSouece[i][1]
		if source1 > 0.0 {
			let source2 = source1 / (valueSouece[i][2] - valueSouece[i][1])
			source = source2 / (source2 + 1.0)
		} else {
			source = 0.0
		}
		valueSouece[i][3] = source
		value *= source
	}
	
	let sideRoads = checkSideRoads()
	value *= sideRoads
	
	if printOn {
		printField(f: field)
		print("length ", field[h - 1][w - 1], valueSouece[0][3])
		print("turn   ", chechTurn(), valueSouece[1][3])
		print("choice ", checkChoiceInAnswer(), valueSouece[2][3])
		print("sideRoads", sideRoads)
		print("total    ", value)
		print("")
	}
	
	return value
}

func printField(f: [[Int]]) {
	guard f.isEmpty == false else {
		print("Empty Field")
		return
	}
	print("ST  ", terminator: "")
	for _ in 0..<f[0].count {
		print("##", terminator: "")
	}
	print("")
	for i in 0..<f.count {
		if i == 0 {
			print("  ", terminator: "")
		} else {
			print("##", terminator: "")
		}
		for j in 0..<f[i].count {
			if f[i][j] == 0 {
				print("##", terminator: "")
			} else {
				print("  ", terminator: "")
			}
		}
		if i == f.count - 1 {
			print("  ")
		} else {
			print("##")
		}
	}
	for _ in 0..<f[0].count {
		print("##", terminator: "")
	}
	print("  GL")
	print()
}

func printFieldN(f: [[Int]]) {
	for i in 0..<f.count {
		for j in 0..<f[i].count {
			if f[i][j] == 0 {
				print("  ", terminator: " ")
			} else if f[i][j] == -1 {
				print("-1", terminator: " ")
			} else {
				print(String(format: "%02d", f[i][j]), terminator: " ")
			}
		}
		print("")
	}
	print("")
}
