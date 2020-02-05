import Foundation

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.subtracting(otherSet))
    }
    
    mutating func move(at i: Int, to j: Int) {
        let element = self.remove(at: i)
        self.insert(element, at: j)
    }
}
