# ♠ TrucoVR

**TrucoVR** is a fully immersive VR adaptation of the classic card game **Truco Paulista**, developed in **Godot Engine 4.4.1** with support for **Meta Quest** and **SteamVR**. Designed for multiplayer and single-player experiences, it features realistic hand tracking, animated cards, bots with multiple difficulty levels, and faithful adherence to the [official rulebook](https://www.jogatina.com/regras-como-jogar-truco.html).

---

## 🎮 Overview

Truco Paulista is a beloved Brazilian card game of bluffing, risk, and strategy. This project brings it to life in virtual reality with:

- Seated multiplayer experience around a 3D table
- Card dealing, vira reveal, manilha logic, and scorekeeping
- Bots with AI logic and difficulty scaling
- Cross-platform deployment (Meta Quest, SteamVR, PC)

---

## ✨ Features

✅ Truco Paulista rules faithfully implemented  
✅ Multiplayer rooms (host or join by code)  
✅ Bots with 4 difficulty levels (Easy, Normal, Hard, Expert)  
✅ Full VR interaction (grab, flip, hover cards with hands)  
✅ Post-match menu for rematches with bot adjustments  
✅ Designed for Android (Quest) and Steam/PC compatibility

---

## 🗂️ Project Structure

```bash
TrucoVR/
├── assets/                 # Card textures, models, sounds
├── scenes/
│   ├── main_menu.tscn      # Main menu with interactive buttons
│   ├── arena.tscn          # Main VR gameplay table
│   ├── deck.tscn           # 3D deck scene
│   └── card.tscn           # Card prefab (double-sided, flip)
├── scripts/
│   ├── arena.gd            # Game logic: turns, flow, UI, Pe
│   ├── card.gd             # Card visuals, hover, flip
│   ├── gameManager.gd      # Turn tracking, winner resolution, rules
│   └── network.gd          # Multiplayer room setup (in progress)
├── plugins/                # Meta XR Toolkit + Godot XR Tools
├── project.godot           # Godot project config
└── README.md               # You're here!
```

---

## 🚀 Getting Started

### ✅ Requirements

- [Godot Engine v4.4.1](https://godotengine.org/)
- Meta Quest 3 (Standalone VR)
- SteamVR-compatible headset (PC VR)
- Vulkan-compatible GPU

### 🛠 Setup Instructions

```bash
# 1. Clone the repository
git clone https://github.com/LeMajaw/TrucoVR.git
cd TrucoVR

# 2. Open Godot and import the project
#    (Choose the project.godot file from the cloned folder)

# 3. (Optional) Configure OpenXR runtime
#    - SteamVR: via SteamVR settings
#    - Meta Quest: via Quest Link (PC) or Android build (Standalone)

# 4. Run the game
#    - Press F5 to run in desktop preview
#    - Deploy to Android for Meta Quest
