import CoreGraphics
import Foundation

/// Determines where the quick capture panel appears (spec §9).
///
/// Pure geometry: takes frames and points so it is fully unit-testable
/// without NSScreen. All inputs use AppKit's bottom-left-origin coordinates.
enum PanelPlacement {
    /// Computes the panel frame for a given mode.
    ///
    /// - Parameters:
    ///   - size: the desired panel size.
    ///   - cursor: the current mouse location in global coordinates.
    ///   - visibleFrame: the screen's visible frame (excludes menu bar/Dock).
    ///   - mode: near cursor or centered.
    static func frame(
        size: CGSize,
        cursor: CGPoint,
        visibleFrame: CGRect,
        mode: SettingsService.PanelPosition,
        margin: CGFloat = DesignTokens.CapturePanel.screenMargin,
        cursorGap: CGFloat = DesignTokens.CapturePanel.cursorGap
    ) -> CGRect {
        switch mode {
        case .nearCursor:
            return clampedFrame(
                nearCursorFrame(
                    size: size,
                    cursor: cursor,
                    visibleFrame: visibleFrame,
                    cursorGap: cursorGap,
                    margin: margin
                ),
                inside: visibleFrame,
                margin: margin
            )
        case .centeredOnScreen:
            let origin = CGPoint(
                x: visibleFrame.midX - size.width / 2,
                y: visibleFrame.midY - size.height / 2
            )
            return clampedFrame(CGRect(origin: origin, size: size), inside: visibleFrame, margin: margin)
        }
    }

    /// Anchors the panel just below-right of the cursor. When there is no room
    /// below (bottom of the screen), the panel is placed above the cursor
    /// instead (spec §9.7).
    private static func nearCursorFrame(
        size: CGSize,
        cursor: CGPoint,
        visibleFrame: CGRect,
        cursorGap: CGFloat,
        margin: CGFloat
    ) -> CGRect {
        let belowOrigin = CGPoint(
            x: cursor.x - size.width * 0.2,
            y: cursor.y - cursorGap - size.height
        )
        var candidate = CGRect(origin: belowOrigin, size: size)

        let insetBounds = visibleFrame.insetBy(dx: margin, dy: margin)
        if candidate.minY < insetBounds.minY {
            // Not enough room below the cursor — flip above it.
            candidate.origin.y = cursor.y + cursorGap
        }
        return candidate
    }

    /// Keeps the entire frame inside the visible area with the given margin.
    static func clampedFrame(_ frame: CGRect, inside bounds: CGRect, margin: CGFloat = DesignTokens.CapturePanel.screenMargin) -> CGRect {
        var origin = frame.origin
        let insetBounds = bounds.insetBy(dx: margin, dy: margin)

        origin.x = min(max(origin.x, insetBounds.minX), max(insetBounds.maxX - frame.width, insetBounds.minX))
        origin.y = min(max(origin.y, insetBounds.minY), max(insetBounds.maxY - frame.height, insetBounds.minY))

        // If the panel is larger than the inset area in a dimension, pin it
        // flush inside the un-insetted bounds so it stays fully on screen.
        if frame.height > insetBounds.height {
            origin.y = bounds.maxY - frame.height
        }
        if frame.width > insetBounds.width {
            origin.x = bounds.minX
        }

        return CGRect(origin: origin, size: frame.size)
    }

    /// Resizes a panel while keeping its top edge fixed (used for dynamic
    /// height growth while typing).
    static func frameResizingDownward(from currentFrame: CGRect, newHeight: CGFloat) -> CGRect {
        var frame = currentFrame
        frame.size.height = newHeight
        frame.origin.y = currentFrame.maxY - newHeight
        return frame
    }
}
