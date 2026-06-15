import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    // -------------------------------------------------------------------------
    // COLORS (Expanded Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0 || "#6c7086"
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // -------------------------------------------------------------------------
    // STATE & LOGIC
    // -------------------------------------------------------------------------
    property var allApps: []

    // --- Horizontal Category Tabs ---
    readonly property var categories: [
        { name: "All", label: "All" },
        { name: "Web", label: "Web", keywords: ["browser", "firefox", "chrome", "opera", "discord", "web", "vivaldi", "brave", "youtube", "netflix", "hoyo", "social", "internet"] },
        { name: "Dev", label: "Dev", keywords: ["code", "neovim", "vim", "studio", "git", "docker", "unity", "unreal", "intellij", "pycharm", "terminal", "kitty", "alacritty", "vscode", "codium"] },
        { name: "Games", label: "Games", keywords: ["steam", "lutris", "heroic", "game", "minecraft", "anime", "retroarch", "osu", "launcher", "play"] },
        { name: "Media", label: "Media", keywords: ["spotify", "vlc", "mpv", "audacity", "obs", "gimp", "inkscape", "blender", "kdenlive", "music", "video", "player", "picture", "photo", "image", "krita"] },
        { name: "System", label: "System", keywords: ["setting", "system", "monitor", "btop", "htop", "config", "file", "thunar", "dolphin", "tweak", "manager", "install", "update", "package", "hidetopbar", "hypr", "quickshell"] }
    ]
    property string activeCategory: "All"

    function isAppInCategory(app, catName) {
        if (catName === "All") return true;
        let cat = null;
        for (let i = 0; i < categories.length; i++) {
            if (categories[i].name === catName) {
                cat = categories[i];
                break;
            }
        }
        if (!cat || !cat.keywords) return true;
        let n = app.name.toLowerCase();
        let e = app.exec.toLowerCase();
        for (let i = 0; i < cat.keywords.length; i++) {
            let kw = cat.keywords[i];
            if (n.includes(kw) || e.includes(kw)) return true;
        }
        return false;
    }

    function cycleCategory(dir) {
        let currentIdx = 0;
        for (let i = 0; i < categories.length; i++) {
            if (categories[i].name === window.activeCategory) {
                currentIdx = i;
                break;
            }
        }
        let nextIdx = (currentIdx + dir + categories.length) % categories.length;
        window.activeCategory = categories[nextIdx].name;
        filterApps(searchInput.text);
    }

    // --- Neon Pulsating Glow ---
    property real glowOpacity: 0.35
    SequentialAnimation on glowOpacity {
        loops: Animation.Infinite
        running: window.visible
        
        NumberAnimation { to: 0.70; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.35; duration: 2200; easing.type: Easing.InOutSine }
    }

    // --- Search Query Highlight ---
    function getHighlightedName(name, query, isSelected) {
        if (!name) return "";
        if (!query || query.trim() === "") return name;
        let q = query.toLowerCase();
        let n = name.toLowerCase();
        let idx = n.indexOf(q);
        if (idx === -1) return name;
        
        let originalMatch = name.substring(idx, idx + query.length);
        let before = name.substring(0, idx);
        let after = name.substring(idx + query.length);
        
        let accentHex = window.mauve.toString();
        if (isSelected) {
            return before + "<u><b><font color='" + accentHex + "'>" + originalMatch + "</font></b></u>" + after;
        } else {
            return before + "<b><font color='" + accentHex + "'>" + originalMatch + "</font></b>" + after;
        }
    }

    Process {
        id: appFetcher
        running: true
        command: ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/app_fetcher.py"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        window.allApps = JSON.parse(this.text);
                        filterApps("");
                    }
                } catch(e) {
                    console.log("Error parsing apps list: ", e);
                }
            }
        }
    }

    ListModel {
        id: appModel
    }

    // --- KEYBOARD NAV TRACKING (For Smart Highlight Morphing) ---
    property bool isKeyboardNav: false
    Timer {
        id: keyboardNavTimer
        interval: 500
        repeat: false
        onTriggered: window.isKeyboardNav = false
    }

    // --- SMART DIFFING FILTER ---
    function filterApps(query) {
        // Disable morphing behavior so the highlight box sticks to the flying item
        window.isKeyboardNav = false;
        if (keyboardNavTimer.running) keyboardNavTimer.stop();

        appList.currentIndex = -1;
        appList.positionViewAtBeginning();

        let q = query.toLowerCase();
        let filtered = [];
        
        for (let i = 0; i < allApps.length; i++) {
            let app = allApps[i];
            let nameMatches = app.name.toLowerCase().includes(q);
            let catMatches = window.isAppInCategory(app, window.activeCategory);
            if (nameMatches && catMatches) {
                filtered.push(app);
            }
        }

        for (let i = appModel.count - 1; i >= 0; i--) {
            let currentName = appModel.get(i).name;
            let keep = false;
            for (let j = 0; j < filtered.length; j++) {
                if (filtered[j].name === currentName) {
                    keep = true;
                    break;
                }
            }
            if (!keep) {
                appModel.remove(i);
            }
        }

        for (let i = 0; i < filtered.length; i++) {
            let targetApp = filtered[i];
            
            if (i < appModel.count) {
                if (appModel.get(i).name !== targetApp.name) {
                    let foundIdx = -1;
                    for (let j = i + 1; j < appModel.count; j++) {
                        if (appModel.get(j).name === targetApp.name) {
                            foundIdx = j;
                            break;
                        }
                    }
                    if (foundIdx !== -1) {
                        appModel.move(foundIdx, i, 1);
                    } else {
                        appModel.insert(i, targetApp);
                    }
                }
            } else {
                appModel.append(targetApp);
            }
        }
        
        if (appModel.count > 0) {
            appList.currentIndex = 0;
        }
    }

    function launchApp(execStr) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exec_cmd([[" + execStr + "]])"]);
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // --- AGGRESSIVE FOCUS MANAGEMENT ---
    Timer {
        id: focusTimer
        interval: 50
        running: true
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Connections {
        target: window
        function onVisibleChanged() {
            if (window.visible) {
                focusTimer.restart();
                introPhaseAnim.restart();
            }
        }
    }

    Keys.onEscapePressed: {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
        event.accepted = true;
    }

    // --- BACKGROUND ORBIT ANIMATION ---
    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // --- MAIN INTRO ANIMATION ---
    property real introPhase: 0
    NumberAnimation on introPhase {
        id: introPhaseAnim
        from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    // --- NEON GLOW BREATHE SHADOW ---
    Rectangle {
        anchors.fill: mainBg
        anchors.margins: -window.s(4)
        radius: mainBg.radius + window.s(4)
        color: "transparent"
        border.width: window.s(3)
        border.color: window.mauve
        opacity: window.glowOpacity
        z: 0
        Behavior on border.color { ColorAnimation { duration: 800 } }
    }

    Rectangle {
        id: mainBg
        width: parent.width
        z: 1
        
        // --- DYNAMIC HEIGHT CALCULATION (Bottom-up Shrinking) ---
        property real searchHeight: window.s(65)
        property real categoryHeight: window.s(40)
        property real separatorHeight: 1
        property real itemHeight: window.s(60)
        property real listSpacing: window.s(4)
        property real maxListHeight: (8 * itemHeight) + (7 * listSpacing)
        
        property real targetListHeight: appModel.count === 0 ? 0 : Math.min((appModel.count * itemHeight) + ((appModel.count - 1) * listSpacing), maxListHeight)
        property real targetMargins: appModel.count > 0 ? window.s(20) : 0

        // Smoothly animated properties for elegant container morphing
        property real animatedListHeight: targetListHeight
        property real animatedMargins: targetMargins

        Behavior on animatedListHeight { 
            NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
        }
        Behavior on animatedMargins { 
            NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
        }
        
        height: searchHeight + categoryHeight + (separatorHeight * 2) + animatedMargins + animatedListHeight

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        radius: window.s(16)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
        border.color: Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.4)
        border.width: 1
        clip: true

        transform: Translate { y: (window.introPhase - 1) * window.s(60) }
        opacity: window.introPhase

        // --- AMBIENT BLOBS ---
        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
            opacity: 0.08
            color: window.mauve
            Behavior on color { ColorAnimation { duration: 1000 } }
        }
        
        Rectangle {
            width: parent.width * 0.9; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
            opacity: 0.06
            color: window.blue
            Behavior on color { ColorAnimation { duration: 1000 } }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --- SEARCH BAR ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.searchHeight
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: window.s(15)
                    anchors.leftMargin: window.s(20)
                    anchors.rightMargin: window.s(20)
                    spacing: window.s(15)

                    Text {
                        text: ""
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(18)
                        color: searchInput.activeFocus ? window.mauve : window.subtext0
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        background: Item {} 
                        color: window.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(16)
                        
                        placeholderText: "Search..."
                        placeholderTextColor: window.subtext0 
                        
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true

                        onTextChanged: filterApps(text)

                        Keys.onTabPressed: {
                            window.cycleCategory(1);
                            event.accepted = true;
                        }
                        Keys.onBacktabPressed: { // Shift+Tab
                            window.cycleCategory(-1);
                            event.accepted = true;
                        }

                        Keys.onDownPressed: {
                            window.isKeyboardNav = true;
                            keyboardNavTimer.restart();
                            if (appList.currentIndex < appModel.count - 1) {
                                appList.currentIndex++;
                            }
                            event.accepted = true;
                        }
                        Keys.onUpPressed: {
                            window.isKeyboardNav = true;
                            keyboardNavTimer.restart();
                            if (appList.currentIndex > 0) {
                                appList.currentIndex--;
                            }
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: {
                            if (appList.currentIndex >= 0 && appList.currentIndex < appModel.count) {
                                launchApp(appModel.get(appList.currentIndex).exec);
                            }
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: {
                            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                            event.accepted = true;
                        }
                    }
                }
            }

            // --- SEPARATOR 1 ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.separatorHeight
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
            }

            // --- CATEGORY TABS ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.categoryHeight
                color: "transparent"
                Layout.leftMargin: window.s(15)
                Layout.rightMargin: window.s(15)
                
                Row {
                    anchors.centerIn: parent
                    spacing: window.s(8)
                    
                    Repeater {
                        model: window.categories
                        
                        Rectangle {
                            height: window.s(28)
                            width: tabText.implicitWidth + window.s(18)
                            radius: window.s(14)
                            color: window.activeCategory === modelData.name 
                                ? Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.18)
                                : "transparent"
                            border.color: window.activeCategory === modelData.name 
                                ? Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.4)
                                : "transparent"
                            border.width: 1
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                            
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: {
                                    let emoji = "";
                                    if (modelData.name === "All") emoji = "📦 ";
                                    else if (modelData.name === "Web") emoji = "🌐 ";
                                    else if (modelData.name === "Dev") emoji = "📝 ";
                                    else if (modelData.name === "Games") emoji = "🎮 ";
                                    else if (modelData.name === "Media") emoji = "🎨 ";
                                    else if (modelData.name === "System") emoji = "💻 ";
                                    return emoji + modelData.label;
                                }
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(11)
                                font.bold: window.activeCategory === modelData.name
                                color: window.activeCategory === modelData.name ? window.mauve : window.subtext0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeCategory = modelData.name;
                                    window.filterApps(searchInput.text);
                                }
                            }
                        }
                    }
                }
            }

            // --- SEPARATOR 2 ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.separatorHeight
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
            }

            // --- APPLICATION LIST ---
            ListView {
                id: appList
                Layout.fillWidth: true
                
                Layout.preferredHeight: mainBg.animatedListHeight
                Layout.topMargin: mainBg.animatedMargins / 2
                Layout.bottomMargin: mainBg.animatedMargins / 2
                Layout.leftMargin: window.s(10)
                Layout.rightMargin: window.s(10)
                
                // clip: true is critical — it masks items that are outside the
                // visible list area so they cannot bleed through during transitions.
                clip: true
                model: appModel
                spacing: mainBg.listSpacing
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                highlightFollowsCurrentItem: false

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                }

                // --- LIST ITEM TRANSITIONS ---
                // Key fix: NO z-layer tricks. The ListView's own clip:true handles
                // masking. Items animate only opacity + scale so they never visually
                // "hang" outside the clipped region. The displaced transition slides
                // existing items to their new positions without fighting the add/remove.

                populate: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 550; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; from: 0.88; to: 1; duration: 600; easing.type: Easing.OutExpo }
                    }
                }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 380; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; from: 0.88; to: 1; duration: 420; easing.type: Easing.OutExpo }
                    }
                }
                
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 280; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; to: 0.88; duration: 300; easing.type: Easing.OutExpo }
                    }
                }
                
                // displaced runs for items that are already in the list and just
                // need to slide to a new position — keep it simple and fast so it
                // finishes well before (or together with) the add transition.
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 380; easing.type: Easing.OutExpo }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: window.s(4)
                        radius: window.s(2)
                        color: window.surface2
                        opacity: 0.5
                    }
                }

                // --- MATTE MORPHING HIGHLIGHT ---
                highlight: Item {}

                delegate: Item {
                    width: ListView.view.width
                    height: mainBg.itemHeight
                    z: 1 
                    
                    transformOrigin: Item.Center 

                    Rectangle {
                        anchors.fill: parent
                        radius: window.s(8)
                        color: "transparent"
                        border.width: window.s(2)
                        border.color: index === appList.currentIndex ? window.mauve : "transparent"
                        
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        transform: Translate {
                            y: index === appList.currentIndex ? -window.s(4) : 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.6
                                }
                            }
                        }

                        scale: index === appList.currentIndex ? 1.02 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: window.s(8)
                            color: window.surface0
                            opacity: ma.containsMouse && index !== appList.currentIndex ? 0.4 : 0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: window.s(10)
                            anchors.leftMargin: window.s(12)
                            spacing: window.s(15)

                            // --- TINTED ICON MATTE BOX ---
                            Rectangle {
                                Layout.preferredWidth: window.s(40)
                                Layout.preferredHeight: window.s(40)
                                radius: window.s(12)
                                
                                color: index === appList.currentIndex ? window.crust : window.surface0
                                border.width: 0 
                                clip: true
                                
                                property real activeScale: index === appList.currentIndex ? 1.15 : 1
                                scale: activeScale
                                Behavior on activeScale { 
                                    NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } 
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

                                Image {
                                    anchors.centerIn: parent
                                    width: window.s(24)
                                    height: window.s(24)
                                    source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                    sourceSize: Qt.size(64, 64)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }
                                
                                // The Matugen Tint Overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(12) 
                                    
                                    color: window.mauve
                                    opacity: index === appList.currentIndex ? 0.25 : 0.08 
                                    
                                    Behavior on opacity { 
                                        NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
                                    }
                                }
                            }

                            Text {
                                id: appText
                                Layout.fillWidth: true
                                text: window.getHighlightedName(model.name, searchInput.text, index === appList.currentIndex)
                                textFormat: Text.StyledText
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(14)
                                font.weight: index === appList.currentIndex ? Font.Bold : Font.Medium
                                color: window.text
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                
                                property real textShift: index === appList.currentIndex ? window.s(6) : 0
                                transform: Translate { x: appText.textShift }
                                
                                Behavior on textShift { 
                                    NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                appList.currentIndex = index;
                                launchApp(model.exec);
                            }
                        }
                    }
                }
            }
        }
    }
}
