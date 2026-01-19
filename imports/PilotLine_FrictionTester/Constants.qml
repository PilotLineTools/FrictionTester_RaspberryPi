pragma Singleton
import QtQuick 6.5

QtObject {

    // ================================
    // Screen Dimensions (10.1" DSI)
    // ================================

    readonly property int width: 1280
    readonly property int height: 800


    // ================================
    // Typography (touch-optimized)
    // ================================

    // Base font sizes (do NOT depend on Qt.application.font)
    readonly property int fontXS: 11
    readonly property int fontSM: 13
    readonly property int fontMD: 15
    readonly property int fontLG: 18
    readonly property int fontXL: 22
    readonly property int fontXXL: 28

    readonly property font font: Qt.font({
        family: Qt.application.font.family,
        pixelSize: fontMD
    })

    readonly property font largeFont: Qt.font({
        family: Qt.application.font.family,
        pixelSize: fontXL,
        weight: Font.DemiBold
    })


    // ================================
    // Touch Sizes
    // ================================

    readonly property int touchMin: 48
    readonly property int touchButton: 56
    readonly property int touchLarge: 64


    // ================================
    // Spacing & Radius
    // ================================

    readonly property int spacingXS: 6
    readonly property int spacingSM: 10
    readonly property int spacingMD: 14
    readonly property int spacingLG: 20
    readonly property int spacingXL: 28

    readonly property int radiusSM: 8
    readonly property int radiusMD: 12
    readonly property int radiusLG: 16


    // ================================
    // Layout
    // ================================

    readonly property int sidebarWidth: 300
    readonly property int topBarHeight: 64
    readonly property int bottomBarHeight: 78


    // ================================
    // Core Background Colors
    // ================================

    // Main app background
    readonly property color bgPrimary: "#0F172A"

    // Card / panel background
    readonly property color bgCard: "#1F2937"

    // Inner surfaces inside cards
    readonly property color bgSurface: "#273449"


    // ================================
    // Accent Colors
    // ================================

    readonly property color accentPrimary: "#5B84F1"
    readonly property color accentSky: "#38BDF8"
    readonly property color accentWarning: "#F59E0B"
    readonly property color accentDanger: "#DC2626"
    readonly property color accentSuccess: "#10B981"


    // ================================
    // Text Colors
    // ================================

    readonly property color textPrimary: "#F9FAFB"
    readonly property color textSecondary: "#CBD5E1"
    readonly property color textMuted: "#9CA3AF"


    // ================================
    // Borders & Dividers
    // ================================

    readonly property color borderDefault: "#374151"
}
