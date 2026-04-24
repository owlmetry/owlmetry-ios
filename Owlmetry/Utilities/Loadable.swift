import Foundation

enum Loadable<Value> {
  case idle
  case loading
  case loaded(Value)
  case empty
  case error(String)
}

extension Loadable: Equatable where Value: Equatable {}
