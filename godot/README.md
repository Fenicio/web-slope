# Slope Runner - Godot Port

This is a Godot 4.2+ port of the web-based 3D skiing game "Slope Runner".

## Game Description

Navigate down a dark snowy slope with your headlamp as your only light source. Collect 3 gems to unlock the exit portal while avoiding obstacles like trees and snow mounds. You have 3 lives, and your speed increases as you progress!

## How to Play

1. Open the project in Godot 4.2 or later
2. Press F5 or click "Run Project" to start the game
3. Controls:
   - **Arrow Keys** or **A/D** - Move left/right
   - **P** or **ESC** - Pause/Resume
4. Objective:
   - Collect all 3 cyan gems
   - Find and reach the green exit portal
   - Avoid obstacles to preserve your 3 lives

## Features

- Third-person 3D perspective
- Dynamic lighting with player headlamp
- Procedural slope generation
- Increasing difficulty (speed increases with distance)
- Atmospheric snow particles
- Dark, foggy environment
- Collectible gems with glowing effects
- Exit portal that appears after collecting all gems
- Lives system
- Pause functionality

## Game Mechanics

- **Player Speed**: 0.3 units/frame lateral movement
- **Base Speed**: 50 km/h (increases with distance)
- **Max Speed**: 120 km/h
- **Lives**: 3 (game over when all lives lost)
- **Gems Required**: 3 (to unlock exit)
- **Collision Detection**: Uses distance-based collision for obstacles and gems

## Project Structure

- `Main.tscn` - Main game scene with all components
- `GameManager.gd` - Central game state management
- `Player.gd` - Player movement and input handling
- `SlopeGenerator.gd` - Infinite slope generation system
- `ObstacleManager.gd` - Obstacle spawning and collision detection
- `GemManager.gd` - Gem spawning, animation, and collection
- `ExitPortal.gd` - Exit portal activation and win condition
- `SnowParticles.gd` - Atmospheric snow particle effects
- `UI.gd` & `UI.tscn` - User interface and screen overlays

## Requirements

- Godot Engine 4.2 or later
- Forward+ rendering

## Differences from Web Version

This Godot port maintains the same core gameplay and mechanics as the original Three.js web version:

- Similar visual style with dark atmosphere and fog
- Equivalent lighting setup (spotlight + point light on player)
- Same collision detection system
- Identical game progression and objectives
- Comparable particle effects
- Matching UI and screen overlays

The main differences are technical implementation details related to the engine differences between Three.js and Godot.

## Credits

Original web version created with Three.js.
Godot port maintains the same gameplay experience and mechanics.
