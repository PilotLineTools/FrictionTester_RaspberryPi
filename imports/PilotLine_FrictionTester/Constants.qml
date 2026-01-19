pragma Singleton
import QtQuick

QtObject {

    // ================================
    // Screen Deminsions
    // ================================

    /* Comment out the unpreferred screen deminsions */

    // 7-Inch screen
    //readonly property int width: 800
    //readonly property int height: 480

    // 10-Inch screen
    readonly property int width: 1280
    readonly property int height: 800

    property string relativeFontDirectory: "fonts"

    /* Edit this comment to add your custom font */
    readonly property font font: Qt.font({
                                             family: Qt.application.font.family,
                                             pixelSize: Qt.application.font.pixelSize
                                         })
    readonly property font largeFont: Qt.font({
                                                  family: Qt.application.font.family,
                                                  pixelSize: Qt.application.font.pixelSize * 1.6
                                              })

    readonly property color backgroundColor: "#c2c2c2"


    // ================================
    // Core Background Colors
    // ================================

    // Main app background (entire window / shell)
    readonly property color bgPrimary: "#0F172A"

    // Card / panel background (containers, sections)
    readonly property color bgCard: "#1F2937"

    // Inner surfaces inside cards (inputs, grouped areas)
    readonly property color bgSurface: "#273449"


    // ================================
    // Accent Colors
    // ================================

    // Primary brand accent (main buttons, active nav item)
    readonly property color accentPrimary: "#5B84F1"

    // Informational / sky accent (sliders, live readings, info icons)
    readonly property color accentSky: "#38BDF8"

    // Warning / heat / active action (heater ON, alerts)
    readonly property color accentWarning: "#F59E0B"


    // ================================
    // Text Colors
    // ================================

    // Primary text (headings, values, critical info)
    readonly property color textPrimary: "#F9FAFB"

    // Secondary text (labels, descriptions, metadata)
    readonly property color textSecondary: "#CBD5E1"

    // Muted / disabled text (inactive states, placeholders)
    readonly property color textMuted: "#9CA3AF"


    // ================================
    // Borders & Dividers
    // ================================

    // Default card border / section divider
    readonly property color borderDefault: "#374151"

}
