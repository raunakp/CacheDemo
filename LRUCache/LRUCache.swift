import Foundation

open class LRUCache {
    
    private var serialQueue: DispatchQueue = {
        let uuid = UUID().uuidString
        let q = DispatchQueue(
            label: String("LRUCache.\(uuid)"))
        return q
    }()
    
    
    private var dict = [String: Any]()
    // Key: Index in array
    private var list = [(key: String, value: Any)]()
    
    func setCacheCapacity(capacity: Int) {
        if capacity != maxCapacity && capacity > 0 {
            maxCapacity = capacity
        }
    }
    
    private(set) var maxCapacity: Int = 10 {
        willSet {
            if list.count > newValue {
                let numEvictions = maxCapacity - newValue
                evict(count: numEvictions)
            }
        }
    }
    
    private func evict(count: Int) {
        serialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            var count = count
            while count > 0 {
                let item = self.list.removeLast()
                self.dict.removeValue(forKey: item.key)
                count -= 1
            }
        }
    }
    
    func set(value: Any, key: String) {
        serialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            if self.list.count >= self.maxCapacity {
                let item = self.list.removeLast()
                self.dict.removeValue(forKey: item.key)
            }
            self.dict[key] = value
            self.list.insert((key, value), at: 0)
        }
    }
    
    func value(forKey key: String) -> Any? {
        var val: Any?
        serialQueue.sync {
            val = dict[key]
        }
        
        if val != nil {
            serialQueue.async { [weak self] in
                guard let self = self else {
                    return
                }
                let foundIndex = self.list.firstIndex { (item) -> Bool in
                    if item.key == key {
                        return true
                    }
                    return false
                }
                if let index = foundIndex {
                    let item = self.list[index]
                    // twice O(n)
                    self.list.remove(at: index)
                    self.list.insert(item, at: 0)
                }
            }
        }
        
        
        return val
    }
    
    func remove(forKey key: String) -> Any? {
        serialQueue.async{ [weak self] in
            guard let self = self else {
                return
            }
            let foundIndex = self.list.firstIndex { (item) -> Bool in
                if item.key == key {
                    return true
                }
                return false
            }
            if let index = foundIndex {
                // O(n)
                self.list.remove(at: index)
                self.dict.removeValue(forKey: key)
            }
        }
    }
    
    func removeAll() {
        serialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.list.removeAll()
            self.dict.removeAll()
        }
    }
    
    var count: Int {
        var count: Int!
        serialQueue.sync {
            count = list.count
        }
        return count
    }
}
