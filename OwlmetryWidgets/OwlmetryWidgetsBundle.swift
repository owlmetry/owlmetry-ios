import SwiftUI
import WidgetKit

@main
struct OwlmetryWidgetsBundle: WidgetBundle {
  var body: some Widget {
    OwlmetrySingleStatWidget()
    OwlmetryQuadWidget()
    OwlmetryDashboardWidget()
  }
}
