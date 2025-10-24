# Slope Runner - 3D Skiing Game

A thrilling first-person 3D skiing game built with Three.js where you navigate down a dark slope, avoiding obstacles and collecting gems.

## Game Overview

Race down an infinite slope in the darkness of night, guided only by your headlamp. Avoid trees and snow mounds while collecting 3 gems to unlock the exit portal and win!

## Features

- **3D Graphics**: Built with Three.js for smooth 3D rendering
- **Dynamic Lighting**: Enhanced headlamp spotlight with rim lighting creates tension with limited visibility
- **Procedural Generation**: Infinite slope with randomly generated obstacles
- **Collectibles**: Find 3 sparkling gems with pulsing lights and glowing rings
- **Physics**: Realistic collision detection with camera shake feedback
- **Visual Effects**:
  - Snow particles and atmospheric fog
  - Camera shake on collisions
  - Sparkling gem effects with rotating rings
  - Pulsing light effects
- **Audio**: Web Audio API sound effects for collisions and gem collection
- **Responsive UI**: Real-time stats display (lives, gems, speed, distance)
- **Pause System**: Pause and resume gameplay anytime with P or ESC

## How to Play

### Controls
- **Arrow Keys** (← →) or **A/D keys**: Move left and right
- **P** or **ESC**: Pause/Resume the game
- Navigate down the slope while avoiding obstacles

### Objective
1. Collect all 3 glowing cyan gems
2. Once all gems are collected, find the green exit portal
3. Pass through the portal to win!

### Gameplay
- You start with 3 lives
- Hitting a tree or mound costs 1 life and triggers:
  - Camera shake effect
  - Brief slowdown
  - Red screen flash
- Lose all lives and it's game over
- Your speed increases as you travel further down the slope
- Pause anytime to check your stats

## Installation & Running

### Play Online (GitHub Pages)
The game is hosted on GitHub Pages and can be played directly at:
`https://[your-username].github.io/web-slope/`

### Local Setup
1. Clone or download this repository
2. Open `index.html` in a modern web browser
3. That's it! No build process or dependencies needed

### Deploy to GitHub Pages
To deploy your own version on GitHub Pages:

1. **Fork or clone this repository**
   ```bash
   git clone https://github.com/[your-username]/web-slope.git
   cd web-slope
   ```

2. **Push to GitHub**
   ```bash
   git push origin main
   ```

3. **Enable GitHub Pages**
   - Go to your repository on GitHub
   - Click **Settings** → **Pages**
   - Under "Source", select **Deploy from a branch**
   - Select branch: **main** (or your default branch)
   - Select folder: **/ (root)**
   - Click **Save**

4. **Access your game**
   - Wait 1-2 minutes for deployment
   - Visit: `https://[your-username].github.io/web-slope/`
   - Your game is now live!

**Note:** The repository includes a `.nojekyll` file to ensure GitHub Pages serves the files correctly without Jekyll processing.

### Requirements
- Modern web browser with WebGL support
- JavaScript enabled
- Works best in Chrome, Firefox, Safari, or Edge

## Technical Details

### Technologies Used
- **Three.js** (v0.160.0) - 3D graphics library (loaded from CDN)
- **Web Audio API** - Sound effects
- **Vanilla JavaScript** - Game logic
- **HTML5 & CSS3** - UI and styling
- **No build process** - Runs directly in browser

### Game Mechanics
- **Infinite Scrolling**: Slope segments loop and regenerate
- **Procedural Generation**: Obstacles spawn randomly ahead of player
- **Collision Detection**: Distance-based collision checking
- **Dynamic Lighting**: Spotlight follows player, illuminating path ahead
- **Particle System**: 1000 snow particles for atmosphere

### Performance
- Optimized for smooth 60 FPS gameplay
- Efficient object pooling for slope segments
- Culling of off-screen objects
- Lightweight particle system

## Game Elements

### Obstacles
- **Trees**: Brown trunk with green foliage, medium hazard
- **Mounds**: Snow mounds, flatter profile

### Collectibles
- **Gems**: Glowing cyan octahedrons that rotate and bob
- Each gem features:
  - Pulsing point light with 15-meter radius
  - Rotating outer ring effect
  - Smooth bobbing animation
  - Dynamic rotation on multiple axes
- Collection triggers:
  - Sound effect
  - Upward zoom animation
  - Expanding ring effect

### Exit Portal
- Green glowing torus ring
- Only appears after collecting all 3 gems
- Rotates continuously
- Pass through to win

## Tips & Strategy
- Don't go too fast - collect gems carefully
- Use the edges of the lit area to spot obstacles early
- The slope edges are safe zones when things get crowded
- Listen for audio cues - they signal important events

## Credits
Created as a demonstration of Three.js 3D game development.

## License
Open source - feel free to modify and improve!
