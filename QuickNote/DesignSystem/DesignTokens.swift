import CoreGraphics

/// Centralized design tokens. All tunable dimensions live here.
enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum CornerRadius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        /// Corner radius of the quick capture panel.
        static let capture: CGFloat = 24
    }

    /// Metrics for the quick capture panel (spec §8).
    enum CapturePanel {
        static let initialWidth: CGFloat = 460
        static let minWidth: CGFloat = 360
        static let maxWidth: CGFloat = 620
        static let initialHeight: CGFloat = 132
        static let minHeight: CGFloat = 96
        static let maxHeight: CGFloat = 360
        /// Distance kept from menu bar / Dock / screen edges when positioning.
        static let screenMargin: CGFloat = 16
        /// Distance between the cursor and the panel edge.
        static let cursorGap: CGFloat = 14
        /// Horizontal padding inside the panel.
        static let horizontalPadding: CGFloat = 18
        /// Vertical padding inside the panel.
        static let verticalPadding: CGFloat = 16
        /// Spacing between the editor area and the hint footer.
        static let footerSpacing: CGFloat = 8
        /// Height reserved for the hint footer.
        static let footerHeight: CGFloat = 18
    }

    enum MainWindow {
        static let defaultWidth: CGFloat = 1120
        static let defaultHeight: CGFloat = 720
        static let minWidth: CGFloat = 860
        static let minHeight: CGFloat = 560
    }
}
