import * as THREE from 'three';

// Game State
const gameState = {
    isPlaying: false,
    isPaused: false,
    lives: 3,
    gemsCollected: 0,
    gemsNeeded: 3,
    speed: 70,
    baseSpeed: 70,
    maxSpeed: 200,
    distance: 0,
    playerX: 0,
    gameOver: false,
    won: false,
    // Skiing mechanics
    playerTilt: 0,          // Current tilt angle (-1 to 1)
    tiltDirection: 0,       // -1 = left, 0 = none, 1 = right
    lastTiltDirection: 0,   // To detect direction changes
    speedBoostTime: 0,      // Time remaining on speed boost
    lateralVelocity: 0,     // Horizontal sliding speed
    dangerLevel: 30,        // Red bar starting position
    dangerSpeed: 0.03       // How fast danger bar rises (increases over time)
};

// Game Constants
const SLOPE_WIDTH = 30;
const SLOPE_SEGMENT_LENGTH = 50;
const PLAYER_SPEED = 0.3;
const COLLISION_RADIUS = 1.5;
const GEM_COLLISION_RADIUS = 2;
// Skiing mechanics constants
const TILT_SPEED = 0.03;           // How fast player tilts
const MAX_TILT = 0.5;              // Maximum tilt angle
const SLIDE_ACCELERATION = 0.015;   // How fast lateral velocity builds up
const LATERAL_DAMPING = 0.98;      // Damping for sliding (less = more damping)
const SPEED_BOOST_DURATION = 500;  // Speed boost duration in ms (0.5 seconds)
const SPEED_BOOST_AMOUNT = 30;     // Speed increase when changing direction
const SPEED_DECAY_RATE = 0.02;     // How fast speed returns to base

// Scene Setup
let scene, camera, renderer;
let player, playerLight;
let slopeSegments = [];
let obstacles = [];
let gems = [];
let particles = [];

// Input
const keys = {
    left: false,
    right: false
};

// Camera shake
let cameraShake = {
    intensity: 0,
    decay: 0.9
};

// Audio Context
let audioContext;
let sounds = {
    gemCollect: null,
    collision: null,
    ambient: null
};

// Initialize the game
function init() {
    // Create scene
    scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x000510, 0.04);

    // Camera setup (third-person view)
    camera = new THREE.PerspectiveCamera(
        75,
        window.innerWidth / window.innerHeight,
        0.1,
        1000
    );
    camera.position.set(0, 8, 10);
    camera.lookAt(0, 0, -10);

    // Renderer setup
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    document.getElementById('game-container').appendChild(renderer.domElement);

    // Ambient light (very dim for atmosphere)
    const ambientLight = new THREE.AmbientLight(0x0a0a20, 0.15);
    scene.add(ambientLight);

    // Moon light (very dim directional light from behind)
    const moonLight = new THREE.DirectionalLight(0x2a3a5f, 0.25);
    moonLight.position.set(5, 40, 20);
    scene.add(moonLight);

    // Rim light for better depth perception
    const rimLight = new THREE.DirectionalLight(0x1a1a3f, 0.2);
    rimLight.position.set(-10, 10, -30);
    scene.add(rimLight);

    // Create player
    createPlayer();

    // Create initial slope segments
    for (let i = 0; i < 10; i++) {
        createSlopeSegment(i);
    }

    // Create initial obstacles and gems
    generateInitialObstacles();

    // Create snow particles
    createSnowParticles();

    // Setup audio
    setupAudio();

    // Setup event listeners
    setupEventListeners();

    // Start animation loop
    animate();
}

function createPlayer() {
    // Player body (skier)
    const playerGeometry = new THREE.ConeGeometry(0.8, 2, 8);
    const playerMaterial = new THREE.MeshStandardMaterial({
        color: 0xff0000,
        emissive: 0x330000
    });
    player = new THREE.Mesh(playerGeometry, playerMaterial);
    player.position.set(0, 1, 0);
    player.rotation.x = Math.PI;
    player.castShadow = true;
    scene.add(player);

    // Player's headlamp (spotlight) - brighter and more focused
    playerLight = new THREE.SpotLight(0xffffdd, 3, 60, Math.PI / 7, 0.4, 1.2);
    playerLight.position.set(0, 5, 0);
    playerLight.target.position.set(0, 0, -25);
    playerLight.castShadow = true;
    playerLight.shadow.mapSize.width = 2048;
    playerLight.shadow.mapSize.height = 2048;
    playerLight.shadow.camera.near = 1;
    playerLight.shadow.camera.far = 60;
    scene.add(playerLight);
    scene.add(playerLight.target);

    // Add point light for local illumination around player
    const pointLight = new THREE.PointLight(0xffeeaa, 1.5, 12);
    pointLight.position.set(0, 3, 0);
    scene.add(pointLight);

    // Store reference for updating
    player.headLight = pointLight;
}

function createSlopeSegment(index) {
    const geometry = new THREE.PlaneGeometry(SLOPE_WIDTH, SLOPE_SEGMENT_LENGTH, 20, 20);

    // Add some terrain variation
    const positions = geometry.attributes.position;
    for (let i = 0; i < positions.count; i++) {
        const x = positions.getX(i);
        const y = positions.getY(i);
        const noise = Math.sin(x * 0.5) * Math.cos(y * 0.3) * 0.5;
        positions.setZ(i, noise);
    }
    geometry.computeVertexNormals();

    const material = new THREE.MeshStandardMaterial({
        color: 0xffffff,
        roughness: 0.9,
        metalness: 0.1
    });

    const slope = new THREE.Mesh(geometry, material);
    slope.rotation.x = -Math.PI / 2;
    slope.position.z = -index * SLOPE_SEGMENT_LENGTH;
    slope.receiveShadow = true;

    scene.add(slope);
    slopeSegments.push(slope);

    return slope;
}

function generateInitialObstacles() {
    // Generate obstacles for visible slope
    for (let z = -50; z > -500; z -= 10) {
        if (Math.random() < 0.3) {
            createObstacle(z);
        }
    }

    // Generate gems
    for (let i = 0; i < gameState.gemsNeeded; i++) {
        createGem(-100 - i * 150);
    }

    // Generate exit (appears after collecting all gems)
    createExit(-600);
}

function createObstacle(zPosition) {
    const obstacleType = Math.random() < 0.6 ? 'tree' : 'mound';

    let obstacle;
    if (obstacleType === 'tree') {
        // Tree
        const group = new THREE.Group();

        // Trunk
        const trunkGeometry = new THREE.CylinderGeometry(0.3, 0.4, 3, 8);
        const trunkMaterial = new THREE.MeshStandardMaterial({ color: 0x4a2511 });
        const trunk = new THREE.Mesh(trunkGeometry, trunkMaterial);
        trunk.position.y = 1.5;
        trunk.castShadow = true;
        group.add(trunk);

        // Foliage
        const foliageGeometry = new THREE.ConeGeometry(2, 4, 8);
        const foliageMaterial = new THREE.MeshStandardMaterial({ color: 0x0d5e0d });
        const foliage = new THREE.Mesh(foliageGeometry, foliageMaterial);
        foliage.position.y = 4;
        foliage.castShadow = true;
        group.add(foliage);

        obstacle = group;
    } else {
        // Mound
        const moundGeometry = new THREE.SphereGeometry(2, 8, 8);
        const moundMaterial = new THREE.MeshStandardMaterial({ color: 0xcccccc });
        obstacle = new THREE.Mesh(moundGeometry, moundMaterial);
        obstacle.scale.y = 0.5;
        obstacle.position.y = 0.5;
        obstacle.castShadow = true;
    }

    // Position obstacle
    const xPosition = (Math.random() - 0.5) * (SLOPE_WIDTH - 4);
    obstacle.position.x = xPosition;
    obstacle.position.z = zPosition;

    scene.add(obstacle);
    obstacles.push({
        mesh: obstacle,
        type: obstacleType,
        x: xPosition,
        z: zPosition
    });

    return obstacle;
}

function createGem(zPosition) {
    const gemGeometry = new THREE.OctahedronGeometry(1, 1);
    const gemMaterial = new THREE.MeshStandardMaterial({
        color: 0x00ffff,
        emissive: 0x00ffff,
        emissiveIntensity: 0.8,
        metalness: 1.0,
        roughness: 0.1
    });
    const gem = new THREE.Mesh(gemGeometry, gemMaterial);

    const xPosition = (Math.random() - 0.5) * (SLOPE_WIDTH - 4);
    gem.position.set(xPosition, 2, zPosition);
    gem.castShadow = true;

    // Add point light to gem - brighter and larger radius
    const gemLight = new THREE.PointLight(0x00ffff, 2, 15);
    gemLight.position.copy(gem.position);
    scene.add(gemLight);

    // Add outer glow ring
    const ringGeometry = new THREE.TorusGeometry(1.5, 0.1, 8, 16);
    const ringMaterial = new THREE.MeshBasicMaterial({
        color: 0x00ffff,
        transparent: true,
        opacity: 0.4
    });
    const ring = new THREE.Mesh(ringGeometry, ringMaterial);
    ring.rotation.x = Math.PI / 2;
    ring.position.copy(gem.position);
    scene.add(ring);

    scene.add(gem);
    gems.push({
        mesh: gem,
        light: gemLight,
        ring: ring,
        x: xPosition,
        z: zPosition,
        collected: false,
        rotation: 0
    });

    return gem;
}

function createExit(zPosition) {
    // Create exit portal (visible only when all gems collected)
    const exitGeometry = new THREE.TorusGeometry(3, 0.5, 16, 100);
    const exitMaterial = new THREE.MeshStandardMaterial({
        color: 0x00ff00,
        emissive: 0x00ff00,
        emissiveIntensity: 0.8
    });
    const exit = new THREE.Mesh(exitGeometry, exitMaterial);
    exit.position.set(0, 3, zPosition);
    exit.rotation.x = Math.PI / 2;
    exit.visible = false;

    scene.add(exit);

    gameState.exit = {
        mesh: exit,
        z: zPosition,
        active: false
    };
}

function createSnowParticles() {
    const particleCount = 1000;
    const particleGeometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const velocities = [];

    for (let i = 0; i < particleCount; i++) {
        positions[i * 3] = (Math.random() - 0.5) * 60; // x
        positions[i * 3 + 1] = Math.random() * 50; // y
        positions[i * 3 + 2] = (Math.random() - 0.5) * 100 - 50; // z

        velocities.push({
            x: (Math.random() - 0.5) * 0.1,
            y: -Math.random() * 0.2 - 0.1,
            z: Math.random() * 0.3
        });
    }

    particleGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    const particleMaterial = new THREE.PointsMaterial({
        color: 0xffffff,
        size: 0.3,
        transparent: true,
        opacity: 0.8,
        blending: THREE.AdditiveBlending
    });

    const particleSystem = new THREE.Points(particleGeometry, particleMaterial);
    scene.add(particleSystem);

    particles.push({
        system: particleSystem,
        velocities: velocities,
        geometry: particleGeometry
    });
}

function updateParticles() {
    particles.forEach(particle => {
        const positions = particle.geometry.attributes.position.array;

        for (let i = 0; i < positions.length / 3; i++) {
            // Update particle position
            positions[i * 3] += particle.velocities[i].x;
            positions[i * 3 + 1] += particle.velocities[i].y;
            positions[i * 3 + 2] += particle.velocities[i].z;

            // Reset particle if it goes too low or too far
            if (positions[i * 3 + 1] < -5) {
                positions[i * 3 + 1] = 50;
            }
            if (positions[i * 3 + 2] > 20) {
                positions[i * 3 + 2] = -80;
            }
        }

        particle.geometry.attributes.position.needsUpdate = true;
    });
}

function setupAudio() {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();

    // Create simple sound effects using Web Audio API
    sounds.gemCollect = () => {
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);

        oscillator.frequency.value = 800;
        gainNode.gain.value = 0.3;

        oscillator.start();
        oscillator.frequency.exponentialRampToValueAtTime(1200, audioContext.currentTime + 0.1);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
        oscillator.stop(audioContext.currentTime + 0.2);
    };

    sounds.collision = () => {
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);

        oscillator.type = 'sawtooth';
        oscillator.frequency.value = 100;
        gainNode.gain.value = 0.3;

        oscillator.start();
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
        oscillator.stop(audioContext.currentTime + 0.3);
    };
}

function setupEventListeners() {
    // Keyboard controls
    document.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
            keys.left = true;
        }
        if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
            keys.right = true;
        }
        if ((e.key === 'p' || e.key === 'P' || e.key === 'Escape') && gameState.isPlaying) {
            togglePause();
        }
    });

    document.addEventListener('keyup', (e) => {
        if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
            keys.left = false;
        }
        if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
            keys.right = false;
        }
    });

    // Start button
    document.getElementById('start-button').addEventListener('click', startGame);

    // Restart buttons
    document.getElementById('restart-button').addEventListener('click', restartGame);
    document.getElementById('restart-win-button').addEventListener('click', restartGame);

    // Window resize
    window.addEventListener('resize', onWindowResize);
}

function startGame() {
    gameState.isPlaying = true;
    gameState.isPaused = false;
    document.getElementById('start-screen').classList.add('hidden');
    document.getElementById('pause-screen').classList.add('hidden');

    // Resume audio context (required for some browsers)
    if (audioContext.state === 'suspended') {
        audioContext.resume();
    }
}

function togglePause() {
    if (gameState.gameOver || gameState.won) return;

    gameState.isPaused = !gameState.isPaused;

    if (gameState.isPaused) {
        // Update pause screen stats
        document.getElementById('pause-distance').textContent = Math.floor(gameState.distance);
        document.getElementById('pause-gems').textContent = gameState.gemsCollected;
        document.getElementById('pause-lives').textContent = gameState.lives;
        document.getElementById('pause-screen').classList.remove('hidden');
    } else {
        document.getElementById('pause-screen').classList.add('hidden');
    }
}

function restartGame() {
    // Reset game state
    gameState.isPlaying = true;
    gameState.lives = 3;
    gameState.gemsCollected = 0;
    gameState.speed = gameState.baseSpeed;
    gameState.distance = 0;
    gameState.playerX = 0;
    gameState.gameOver = false;
    gameState.won = false;
    // Reset skiing mechanics
    gameState.playerTilt = 0;
    gameState.tiltDirection = 0;
    gameState.lastTiltDirection = 0;
    gameState.speedBoostTime = 0;
    gameState.lateralVelocity = 0;
    gameState.dangerLevel = 30;
    gameState.dangerSpeed = 0.03;

    // Reset player position and rotation
    player.position.set(0, 1, 0);
    player.rotation.z = 0;

    // Clear and regenerate obstacles and gems
    obstacles.forEach(obs => scene.remove(obs.mesh));
    obstacles = [];

    gems.forEach(gem => {
        scene.remove(gem.mesh);
        scene.remove(gem.light);
        scene.remove(gem.ring);
    });
    gems = [];

    // Reset exit
    if (gameState.exit) {
        gameState.exit.mesh.visible = false;
        gameState.exit.active = false;
    }

    // Regenerate
    generateInitialObstacles();

    // Hide screens
    document.getElementById('gameover-screen').classList.add('hidden');
    document.getElementById('win-screen').classList.add('hidden');

    // Update UI
    updateUI();
}

function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
}

function updatePlayer() {
    if (!gameState.isPlaying || gameState.gameOver || gameState.won || gameState.isPaused) return;

    // Determine desired tilt direction based on input
    let desiredTiltDirection = 0;
    if (keys.left) desiredTiltDirection = -1;
    if (keys.right) desiredTiltDirection = 1;

    // Detect direction change for speed boost
    if (desiredTiltDirection !== 0 && desiredTiltDirection !== gameState.lastTiltDirection && gameState.lastTiltDirection !== 0) {
        // Direction changed! Apply speed boost
        gameState.speedBoostTime = SPEED_BOOST_DURATION;
        gameState.speed = Math.min(gameState.speed + SPEED_BOOST_AMOUNT, gameState.maxSpeed);
    }

    // Update tilt direction tracking
    if (desiredTiltDirection !== 0) {
        gameState.tiltDirection = desiredTiltDirection;
        gameState.lastTiltDirection = desiredTiltDirection;
    }

    // Gradually tilt towards desired direction
    const targetTilt = desiredTiltDirection * MAX_TILT;
    if (Math.abs(gameState.playerTilt - targetTilt) > 0.01) {
        gameState.playerTilt += (targetTilt - gameState.playerTilt) * TILT_SPEED * 3;
    } else {
        gameState.playerTilt = targetTilt;
    }

    // Apply tilt to player mesh (rotate on Z axis for side tilt)
    player.rotation.z = -gameState.playerTilt;

    // Build up lateral velocity based on tilt
    if (gameState.playerTilt !== 0) {
        gameState.lateralVelocity += gameState.playerTilt * SLIDE_ACCELERATION;
    }

    // Apply damping to lateral velocity
    gameState.lateralVelocity *= LATERAL_DAMPING;

    // Move player based on lateral velocity
    gameState.playerX += gameState.lateralVelocity;

    // Constrain player to slope
    const maxX = SLOPE_WIDTH / 2 - 2;
    gameState.playerX = Math.max(-maxX, Math.min(maxX, gameState.playerX));

    player.position.x = gameState.playerX;

    // Update player's light position
    playerLight.position.set(gameState.playerX, 5, player.position.z);
    playerLight.target.position.set(gameState.playerX, 0, player.position.z - 20);
    player.headLight.position.set(gameState.playerX, 3, player.position.z);

    // Update distance
    gameState.distance += gameState.speed * 0.016;

    // Handle speed boost countdown
    if (gameState.speedBoostTime > 0) {
        gameState.speedBoostTime -= 16; // Assuming 60fps (16ms per frame)
    }

    // Gradually decrease speed towards base speed (when not boosting)
    if (gameState.speedBoostTime <= 0 && gameState.speed > gameState.baseSpeed) {
        gameState.speed -= SPEED_DECAY_RATE;
        gameState.speed = Math.max(gameState.speed, gameState.baseSpeed);
    }

    // Increase danger level over time (speeds up as game progresses)
    gameState.dangerLevel += gameState.dangerSpeed;
    gameState.dangerSpeed += 0.00001; // Gradually increase danger speed

    // Check if danger bar caught up to player speed - GAME OVER
    if (gameState.dangerLevel >= gameState.speed) {
        handleDangerOverload();
    }
}

function updateSlope() {
    if (!gameState.isPlaying || gameState.gameOver || gameState.won || gameState.isPaused) return;

    const scrollSpeed = gameState.speed * 0.016;

    // Move slope segments
    slopeSegments.forEach((segment, index) => {
        segment.position.z += scrollSpeed;

        // If segment is behind camera, move it to the front
        if (segment.position.z > 25) {
            segment.position.z -= slopeSegments.length * SLOPE_SEGMENT_LENGTH;
        }
    });

    // Move obstacles
    obstacles.forEach((obs, index) => {
        obs.mesh.position.z += scrollSpeed;
        obs.z = obs.mesh.position.z;

        // Remove obstacles that are too far behind
        if (obs.z > 20) {
            scene.remove(obs.mesh);
            obstacles.splice(index, 1);

            // Add new obstacle ahead
            const newZ = -450 + Math.random() * 50;
            createObstacle(newZ);
        }
    });

    // Move and animate gems
    gems.forEach((gem, index) => {
        if (!gem.collected) {
            gem.mesh.position.z += scrollSpeed;
            gem.light.position.z += scrollSpeed;
            gem.ring.position.z += scrollSpeed;
            gem.z = gem.mesh.position.z;

            // Rotate gem
            gem.rotation += 0.03;
            gem.mesh.rotation.y = gem.rotation;
            gem.mesh.rotation.x = Math.sin(gem.rotation) * 0.2;

            // Rotate ring in opposite direction
            gem.ring.rotation.z = -gem.rotation * 0.5;

            // Bob up and down
            const bobHeight = 2 + Math.sin(gem.rotation * 2) * 0.5;
            gem.mesh.position.y = bobHeight;
            gem.light.position.y = bobHeight;
            gem.ring.position.y = bobHeight - 0.5;

            // Pulse the light intensity
            gem.light.intensity = 2 + Math.sin(gem.rotation * 3) * 0.5;
        }
    });

    // Move exit
    if (gameState.exit) {
        gameState.exit.mesh.position.z += scrollSpeed;
        gameState.exit.z = gameState.exit.mesh.position.z;

        // Rotate exit
        gameState.exit.mesh.rotation.z += 0.02;
    }
}

function checkCollisions() {
    if (!gameState.isPlaying || gameState.gameOver || gameState.won || gameState.isPaused) return;

    // Check obstacle collisions
    obstacles.forEach(obs => {
        const dx = obs.x - gameState.playerX;
        const dz = obs.z - player.position.z;
        const distance = Math.sqrt(dx * dx + dz * dz);

        if (distance < COLLISION_RADIUS) {
            handleCollision();
        }
    });

    // Check gem collisions
    gems.forEach(gem => {
        if (!gem.collected) {
            const dx = gem.x - gameState.playerX;
            const dz = gem.z - player.position.z;
            const distance = Math.sqrt(dx * dx + dz * dz);

            if (distance < GEM_COLLISION_RADIUS) {
                collectGem(gem);
            }
        }
    });

    // Check exit collision
    if (gameState.exit && gameState.exit.active) {
        const dz = gameState.exit.z - player.position.z;
        if (Math.abs(dz) < 5 && Math.abs(gameState.playerX) < 5) {
            winGame();
        }
    }
}

function handleCollision() {
    if (gameState.gameOver) return;

    sounds.collision();
    gameState.lives--;

    // Trigger camera shake
    cameraShake.intensity = 0.5;

    // Flash screen red
    scene.fog.color.setHex(0x330000);
    setTimeout(() => {
        scene.fog.color.setHex(0x000510);
    }, 100);

    // Slow down briefly
    const originalSpeed = gameState.speed;
    gameState.speed *= 0.5;
    setTimeout(() => {
        if (!gameState.gameOver) {
            gameState.speed = originalSpeed;
        }
    }, 500);

    if (gameState.lives <= 0) {
        gameOver();
    }

    updateUI();
}

function handleDangerOverload() {
    if (gameState.gameOver) return;

    // The danger bar has caught up to the player's speed - game over!
    gameState.gameOver = true;
    gameState.isPlaying = false;

    // Flash screen red
    scene.fog.color.setHex(0x550000);
    setTimeout(() => {
        scene.fog.color.setHex(0x000510);
    }, 200);

    // Show game over screen with special message
    document.getElementById('gameover-distance').textContent = Math.floor(gameState.distance);
    document.getElementById('gameover-gems').textContent = gameState.gemsCollected;
    document.getElementById('gameover-reason').textContent = 'You were too slow! The danger caught up!';
    document.getElementById('gameover-screen').classList.remove('hidden');
}

function collectGem(gem) {
    gem.collected = true;
    gameState.gemsCollected++;

    sounds.gemCollect();

    // Animate gem collection
    const startY = gem.mesh.position.y;
    let animTime = 0;
    const animInterval = setInterval(() => {
        animTime += 0.05;
        gem.mesh.position.y = startY + animTime * 10;
        gem.mesh.scale.multiplyScalar(0.9);
        gem.ring.scale.multiplyScalar(1.1);
        gem.ring.material.opacity *= 0.8;
        gem.light.intensity *= 0.85;

        if (animTime > 0.5) {
            clearInterval(animInterval);
            scene.remove(gem.mesh);
            scene.remove(gem.light);
            scene.remove(gem.ring);
        }
    }, 16);

    // Check if all gems collected
    if (gameState.gemsCollected >= gameState.gemsNeeded) {
        activateExit();
    }

    updateUI();
}

function activateExit() {
    if (gameState.exit) {
        gameState.exit.active = true;
        gameState.exit.mesh.visible = true;

        // Show notification
        showNotification('All gems collected! Find the exit portal!');
    }
}

function showNotification(message) {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.classList.remove('hidden');

    setTimeout(() => {
        notification.classList.add('hidden');
    }, 3000);
}

function gameOver() {
    gameState.gameOver = true;
    gameState.isPlaying = false;

    // Show game over screen
    document.getElementById('gameover-distance').textContent = Math.floor(gameState.distance);
    document.getElementById('gameover-gems').textContent = gameState.gemsCollected;
    document.getElementById('gameover-reason').textContent = 'You crashed into too many obstacles!';
    document.getElementById('gameover-screen').classList.remove('hidden');
}

function winGame() {
    gameState.won = true;
    gameState.isPlaying = false;

    // Show win screen
    document.getElementById('final-distance').textContent = Math.floor(gameState.distance);
    document.getElementById('win-screen').classList.remove('hidden');
}

function updateUI() {
    document.getElementById('lives-count').textContent = gameState.lives;
    document.getElementById('gems-count').textContent = `${gameState.gemsCollected}/${gameState.gemsNeeded}`;
    document.getElementById('speed-count').textContent = Math.floor(gameState.speed);
    document.getElementById('distance-count').textContent = Math.floor(gameState.distance);

    // Update speed bars
    const speedBarFill = document.getElementById('speed-bar-fill');
    const dangerBarFill = document.getElementById('danger-bar-fill');

    if (speedBarFill && dangerBarFill) {
        // Calculate percentages (based on max speed)
        const speedPercent = (gameState.speed / gameState.maxSpeed) * 100;
        const dangerPercent = (gameState.dangerLevel / gameState.maxSpeed) * 100;

        speedBarFill.style.height = `${speedPercent}%`;
        dangerBarFill.style.height = `${dangerPercent}%`;

        // Change color if danger is close
        if (gameState.dangerLevel >= gameState.speed * 0.9) {
            speedBarFill.style.background = 'linear-gradient(to top, #ff0000, #ff6600)';
        } else if (gameState.speedBoostTime > 0) {
            speedBarFill.style.background = 'linear-gradient(to top, #00ff00, #00ffff)';
        } else {
            speedBarFill.style.background = 'linear-gradient(to top, #0088ff, #00ffff)';
        }
    }
}

function updateCamera() {
    // Apply camera shake
    if (cameraShake.intensity > 0.01) {
        camera.position.x += (Math.random() - 0.5) * cameraShake.intensity;
        camera.position.y += (Math.random() - 0.5) * cameraShake.intensity;
        cameraShake.intensity *= cameraShake.decay;
    } else {
        // Reset camera position smoothly
        camera.position.x += (0 - camera.position.x) * 0.1;
        camera.position.y += (8 - camera.position.y) * 0.1;
    }
}

function animate() {
    requestAnimationFrame(animate);

    updatePlayer();
    updateSlope();
    updateParticles();
    updateCamera();
    checkCollisions();
    updateUI();

    renderer.render(scene, camera);
}

// Initialize game when page loads
init();
