# Void Runner FP

A fast-paced first-person space shooter where you pilot through an endless void, dodging asteroids and battling enemy spacecraft.

## 🎮 Overview

Void Runner FP is an action-packed 3D space shooter built with Swift and SceneKit. Fly through procedurally generated space environments, destroy enemy ships, dodge asteroids, and survive as long as possible in this high-speed runner-shooter hybrid.

## ✨ Features

### Combat System
- **Fast-Paced Shooting**: Rapid-fire laser weapons (0.11s cooldown)
- **Enemy Variety**: Multiple enemy types including Drones and Fighters
- **Projectile Combat**: Player lasers (300 units/sec) vs enemy lasers (150 units/sec)
- **Hit Detection**: Collision-based combat system

### Movement & Controls
- **Forward Auto-Scroll**: Constant forward momentum (90 units/sec)
- **Lateral Movement**: Side-to-side dodging (38 units/sec)
- **Boundary System**: Play area bounds (±16 X, ±10 Y)
- **Smooth Controls**: Responsive keyboard input

### Obstacles & Hazards
- **Asteroid Fields**: Procedurally spawned rotating asteroids
- **Varying Sizes**: Dynamic asteroid scaling (0.6-1.3x)
- **Rotation Effects**: Randomized tumbling animations
- **Spawn System**: Objects spawn at 380 units ahead, removed at 60 units behind

### Visual Design
- **Neon Aesthetic**: Vibrant colors (Cyan, Magenta, Red, Orange, Green, Purple, Gold)
- **Emissive Materials**: Glowing enemy cores and weapons
- **Dark Space**: Gunmetal and dark grey ship hulls
- **Particle Effects**: Laser trails and explosions

### Enemy AI
- **Drone Type**: Spherical enemies with rotating fins and orange cores
- **Fighter Type**: Cone-shaped ships with wings and weapons
- **Attack Patterns**: Enemies fire projectiles at player
- **Visual Distinction**: Color-coded enemy types with emissive highlights

## 🕹️ Controls

- **Arrow Keys / WASD**: Move ship laterally and vertically
- **Spacebar / Mouse**: Fire lasers
- **Auto-Forward**: Ship constantly moves forward

## 🎯 Game Mechanics

### Speed Settings
- **Forward Speed**: 90 units/second
- **Lateral Speed**: 38 units/second
- **Laser Speed**: 300 units/second
- **Enemy Laser Speed**: 150 units/second

### Combat Stats
- **Fire Rate**: 0.11 second cooldown
- **Spawn Distance**: 380 units ahead
- **Despawn Distance**: 60 units behind

### Play Area
- **Window Size**: 1280 x 720
- **Horizontal Bounds**: ±16 units
- **Vertical Bounds**: ±10 units

## 🛠️ Tech Stack

- **Language**: Swift
- **3D Engine**: SceneKit
- **UI Framework**: SpriteKit (HUD)
- **Graphics**: AppKit
- **Platform**: macOS

## 🚀 Getting Started

### Prerequisites
- macOS 10.15 or later
- Xcode 13.0 or later
- Swift 5.5+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/kevmart15/void-runner-fp.git
cd void-runner-fp
```

2. Compile the game:
```bash
swiftc main.swift -o void-runner-fp -framework AppKit -framework SceneKit -framework SpriteKit
```

3. Run the game:
```bash
./void-runner-fp
```

Or run the pre-built app:
```bash
open VoidRunnerFP.app
```

## 🎮 Gameplay Tips

1. **Keep Moving**: Staying in one spot makes you an easy target
2. **Lead Your Shots**: Enemies move fast, aim where they're going
3. **Prioritize Targets**: Fighters are more dangerous than drones
4. **Use the Full Arena**: Don't just fly straight, use vertical and horizontal space
5. **Watch Ahead**: Asteroids spawn far away, giving you time to react

## 🏗️ Technical Highlights

- **Procedural Spawning**: Dynamic obstacle and enemy generation
- **3D Vector Mathematics**: Smooth movement and projectile physics
- **Material System**: Emissive materials for glowing effects
- **Action System**: SceneKit actions for smooth animations
- **Efficient Culling**: Objects removed when off-screen to maintain performance

## 📊 Game Flow

1. **Start**: Begin flying forward through space
2. **Dodge**: Navigate around asteroids
3. **Shoot**: Destroy approaching enemies
4. **Survive**: Last as long as possible
5. **Repeat**: Increasing difficulty as you progress

## 📜 License

This project is open source and available under the MIT License.

## 👤 Author

**kevmart15**
- GitHub: [@kevmart15](https://github.com/kevmart15)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

---

*Fly fast. Shoot straight. Survive the void.* 🚀
