import Foundation

enum ProblemType: String, CaseIterable, Identifiable, Sendable {
    case addition = "addition"
    case subtraction = "subtraction"
    case mixed = "mixed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .addition: return "＋ たし算"
        case .subtraction: return "－ ひき算"
        case .mixed: return "± ミックス"
        }
    }

    var icon: String {
        switch self {
        case .addition: return "plus"
        case .subtraction: return "minus"
        case .mixed: return "plusminus"
        }
    }
}

struct Problem: Sendable {
    let a: Int
    let b: Int
    let answer: Int
    let operatorSymbol: String
    let choices: [Int]
    let isReview: Bool

    static func generate(floor: Int, mistakeLog: [MistakeEntry], difficulty: Difficulty = .hard, problemType: ProblemType = .mixed) -> Problem {
        // 20% chance to use a review problem (problemType+現フロア難易度に従う)
        if !mistakeLog.isEmpty && Int.random(in: 1...5) == 1 {
            let config = DifficultyConfig.forFloor(floor, difficulty: difficulty)

            // 演算子でフィルター + 現フロアの数値範囲内のみ
            let addEntries = mistakeLog.filter { $0.a + $0.b == $0.answer && $0.a <= config.maxA && $0.b <= config.maxB }
            let subEntries = mistakeLog.filter { $0.a - $0.b == $0.answer && $0.a <= config.maxA + config.maxB && $0.b <= config.maxB }

            let filtered: [MistakeEntry]
            switch problemType {
            case .addition:    filtered = addEntries
            case .subtraction: filtered = subEntries
            case .mixed:       filtered = addEntries + subEntries
            }

            if let entry = filtered.randomElement() {
                let isSubtraction = entry.a - entry.b == entry.answer
                if isSubtraction {
                    // 元の引き算をそのまま復習
                    let choices = generateChoices(answer: entry.answer, floor: floor, difficulty: difficulty)
                    return Problem(a: entry.a, b: entry.b, answer: entry.answer, operatorSymbol: "－", choices: choices, isReview: true)
                } else {
                    return makeAddition(a: entry.a, b: entry.b, floor: floor, difficulty: difficulty, isReview: true)
                }
            }
        }

        let config = DifficultyConfig.forFloor(floor, difficulty: difficulty)
        let a = Int.random(in: config.minA...config.maxA)
        let b = Int.random(in: config.minB...config.maxB)

        let useSubtraction: Bool
        switch problemType {
        case .addition: useSubtraction = false
        case .subtraction: useSubtraction = true
        case .mixed: useSubtraction = Bool.random()
        }

        if useSubtraction {
            return makeSubtraction(a: a, b: b, floor: floor, difficulty: difficulty)
        } else {
            return makeAddition(a: a, b: b, floor: floor, difficulty: difficulty, isReview: false)
        }
    }

    // MARK: - たし算

    private static func makeAddition(a: Int, b: Int, floor: Int, difficulty: Difficulty, isReview: Bool) -> Problem {
        let answer = a + b
        let choices = generateChoices(answer: answer, floor: floor, difficulty: difficulty)
        return Problem(a: a, b: b, answer: answer, operatorSymbol: "＋", choices: choices, isReview: isReview)
    }

    // MARK: - ひき算

    private static func makeSubtraction(a: Int, b: Int, floor: Int, difficulty: Difficulty, isReview: Bool = false) -> Problem {
        // a + b を被減数にして、a or b を減数にする → 答えが必ず 0 以上
        let sum = a + b
        let subtrahend = Bool.random() ? a : b
        let answer = sum - subtrahend
        let choices = generateChoices(answer: answer, floor: floor, difficulty: difficulty)
        return Problem(a: sum, b: subtrahend, answer: answer, operatorSymbol: "－", choices: choices, isReview: isReview)
    }

    // MARK: - くもん1年生マスターモード問題生成

    static func generateMastery(phase: MasteryPhase) -> Problem {
        switch phase {
        case .addition:
            // 答えが1〜10の足し算
            let a = Int.random(in: 1...9)
            let maxB = 10 - a
            let b = Int.random(in: 1...max(1, maxB))
            let answer = a + b
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "＋",
                           choices: simpleMasteryChoices(answer: answer), isReview: false)

        case .carryAddition:
            // 答えが11〜20のくり上がり足し算
            let a = Int.random(in: 2...9)
            let minB = max(1, 11 - a)
            let maxB = min(9, 20 - a)
            let b = Int.random(in: minB...max(minB, maxB))
            let answer = a + b
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "＋",
                           choices: simpleMasteryChoices(answer: answer), isReview: false)

        case .subtraction:
            // くり下がりなし引き算（a≤10）
            let a = Int.random(in: 2...10)
            let b = Int.random(in: 1...(a - 1))
            let answer = a - b
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "－",
                           choices: simpleMasteryChoices(answer: answer), isReview: false)

        case .borrowSubtraction:
            // くり下がりあり引き算（a=11〜18）
            let a = Int.random(in: 11...18)
            let ones = a % 10
            let minB = ones + 1
            let maxB = min(9, a - 2)
            let b = Int.random(in: minB...max(minB, maxB))
            let answer = a - b
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "－",
                           choices: simpleMasteryChoices(answer: answer), isReview: false)
        }
    }

    private static func simpleMasteryChoices(answer: Int) -> [Int] {
        var choices = Set<Int>()
        choices.insert(answer)
        var attempts = 0
        while choices.count < 4 && attempts < 50 {
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let wrong = answer + offset
            if wrong >= 0 && wrong != answer { choices.insert(wrong) }
            attempts += 1
        }
        var idx = 1
        while choices.count < 4 {
            let c = answer + idx
            if c >= 0 && !choices.contains(c) { choices.insert(c) }
            idx += 1
        }
        return Array(choices).shuffled()
    }

    // MARK: - 選択肢生成

    private static func generateChoices(answer: Int, floor: Int, difficulty: Difficulty) -> [Int] {
        let config = DifficultyConfig.forFloor(floor, difficulty: difficulty)
        var choices = Set<Int>()
        choices.insert(answer)

        while choices.count < 4 {
            let offset = Int.random(in: 1...config.errorRange) * (Bool.random() ? 1 : -1)
            let wrong = answer + offset
            if wrong >= 0 && wrong != answer {
                choices.insert(wrong)
            }
        }

        var idx = 1
        while choices.count < 4 {
            let candidate = answer + idx
            if !choices.contains(candidate) && candidate >= 0 {
                choices.insert(candidate)
            }
            idx += 1
        }

        return Array(choices).shuffled()
    }
}
