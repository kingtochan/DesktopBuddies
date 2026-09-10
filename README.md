# 🚶 Desktop Buddies (DeskWalkers)

A native macOS desktop companion app designed specifically for **Apple Silicon (ARM64) Macs**. Adorable animated little people walk, run, sit, cheer, and nap on your desktop or wallpaper, with fully customizable faces using your own uploaded photos!

> **No Apple Developer License Required!**  
> Desktop Buddies is compiled locally and signed with native macOS ad-hoc code signing (`codesign -s -`), allowing it to run smoothly and permanently on your Mac without any Apple Developer Program membership, certificates, or sandbox restrictions.

---

## ✨ Features

- 📸 **Custom Photo Faces**: Right-click any buddy or use the menu bar to upload your own picture (PNG, JPG, HEIC, WebP). The face is automatically centered, circular-cropped, and formatted as a cute avatar with expressive overlays.
- 🎨 **Built-in Cartoon Faces**: Diverse procedural chibi avatars (smiling, anime, cool sunglasses, kitty ears, beanie, robot) available immediately even before uploading photos.
- 🦵 **Dynamic Kinematics & Physics**:
  - Natural walking, running sprints, sitting down, and napping routines.
  - Realistic gravity, floor detection (screen bottom & dock awareness), boundary bounces, and soft landings.
  - Multi-monitor aware: Buddies can walk and land across external displays.
- 👆 **Rich Interactive Gestures**:
  - **Single Click**: Pokes or pushes the buddy forward! If sleeping, wakes them up with an exclamation mark `❗`.
  - **Double Click**: Triggers a joyful dance & cheer with hearts `💖`.
  - **Click & Drag**: Pick up any buddy—they dangle and kick their legs in surprise `(O_O)`. Release or fling them to let gravity bring them back down with a bounce.
  - **Right Click**: Opens an instant context menu on the desktop to change photos, switch colors, scale size, push, or nap.
- 🪟 **Display Layer Modes**:
  - **Float Above Windows**: Buddies walk right over your browser, code editor, and documents.
  - **On Desktop Wallpaper**: Buddies walk behind open windows directly on your desktop wallpaper.
- 🔊 **Subtle macOS System Sounds**: Gentle audio feedback (Pop, Tink, Bottle, Basso, Hero) on pokes, drops, and cheers (can be muted anytime).
- 🧭 **Menu Bar Status Item**: Discreet control center in your macOS menu bar (top right) to spawn new companions, wake/sleep all, adjust settings, or quit.
- ⚙️ **Buddy Manager Window**: Visual roster to customize names, shirt colors, scales, and photos in one place.
- 💾 **Persistent**: All buddies, customized photos, shirt colors, scales, and positions are automatically saved to `~/Library/Application Support/DesktopBuddies/`.

---

## 🚀 Quick Start

### 1. Launch Immediately
From the project folder, simply run:
```bash
open DesktopBuddies.app
```
Look at your screen bottom or menu bar—your first buddy **Pip** is already walking around!

### 2. Install to Applications (Optional)
To keep Desktop Buddies in your Applications folder:
```bash
cp -R DesktopBuddies.app /Applications/
```

### 3. Rebuilding from Source
If you ever modify the code, rebuild and package in one command:
```bash
./build_app.sh
```
Or build and launch immediately:
```bash
./build_app.sh --run
```

---

## 🎮 How to Interact

| Action | What Happens |
| :--- | :--- |
| **Click Buddy** | Pokes/nudges them forward! If sleeping, wakes them up `⏰` |
| **Double Click Buddy** | Makes them do a happy dance with hearts `💖` |
| **Click & Hold + Drag** | Picks them up into the air; throw them and watch gravity pull them down! |
| **Right-Click Buddy** | Opens context menu: Upload face photo, change outfit color, resize, nap, etc. |
| **Menu Bar Icon (🚶)** | Spawns new buddies, toggles Wallpaper vs Floating layer, opens settings, or quits |

---

## 📁 Project Structure

```text
├── Sources/DesktopBuddies/
│   ├── App/
│   │   ├── AppDelegate.swift          # Accessory mode, lifecycle coordination
│   │   └── StatusItemManager.swift    # macOS menu bar status icon & action menu
│   ├── Models/
│   │   ├── Buddy.swift                # Buddy data model (position, state, photo path)
│   │   ├── BuddyState.swift           # States (walking, idle, sleeping, dragged, etc.)
│   │   └── BuddyManager.swift         # 60 FPS physics engine, multi-monitor AI logic
│   ├── Views/
│   │   ├── BuddyView.swift            # Top-level buddy view + context menu
│   │   ├── FaceView.swift             # Custom photo renderer & procedural cartoon faces
│   │   ├── BuddyBodyView.swift        # Animated torso, limbs, shoes, and kinematics
│   │   ├── EmoteOverlayView.swift     # Comic-style speech/reaction bubbles (Zzz, !, ❤️)
│   │   └── SettingsWindow.swift       # Visual buddy manager & customization window
│   ├── Windowing/
│   │   ├── BuddyPanel.swift           # Transparent borderless NSPanel with gesture routing
│   │   └── WindowManager.swift        # Multi-window coordinator
│   ├── Utilities/
│   │   ├── FaceStorage.swift          # Image picker, circular cropper, local cache
│   │   └── SoundManager.swift         # macOS native sound effects
│   └── main.swift                     # AppKit entry point
├── build_app.sh                       # Automates release build, icon, plist, and ad-hoc signing
└── Package.swift                      # Swift Package definition (macOS 13+)
```
