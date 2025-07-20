# Deploying Apex Flow Circuit to itch.io

## Prerequisites

1. **itch.io Account**
   - Go to https://itch.io
   - Click "Register" and create an account
   - Verify your email address

2. **Godot Export Templates**
   - Open your project in Godot 4.3
   - Go to Editor → Manage Export Templates
   - Download and install the templates

## Export Process

### Step 1: Export the Game

1. Open Godot and load your project
2. Go to Project → Export
3. You'll see four presets already configured:
   - Windows Desktop
   - Linux/X11
   - Web
   - macOS

4. For each platform:
   - Select the preset
   - Click "Export Project"
   - The files will be saved to:
     - Windows: `builds/windows/ApexFlowCircuit.exe`
     - Linux: `builds/linux/ApexFlowCircuit.x86_64`
     - Web: `builds/web/index.html`
     - macOS: `builds/macos/ApexFlowCircuit.zip`

### Step 2: Prepare Files for Upload

1. **Windows Build**:
   - Navigate to `builds/windows/`
   - Create a ZIP file containing `ApexFlowCircuit.exe` and `ApexFlowCircuit.pck`
   - Name it: `ApexFlowCircuit-Windows.zip`

2. **Linux Build**:
   - Navigate to `builds/linux/`
   - Create a ZIP file containing the `.x86_64` file
   - Name it: `ApexFlowCircuit-Linux.zip`

3. **Web Build**:
   - Navigate to `builds/web/`
   - Create a ZIP file containing ALL files (index.html, .js, .wasm, .pck files)
   - Name it: `ApexFlowCircuit-Web.zip`

4. **macOS Build**:
   - The macOS export already creates a ZIP file
   - It will be at `builds/macos/ApexFlowCircuit.zip`
   - This contains the .app bundle

## Publishing on itch.io

### Step 1: Create Game Page

1. Log into itch.io
2. Go to Dashboard (https://itch.io/dashboard)
3. Click "Create new project"

### Step 2: Fill in Game Details

1. **Title**: Apex Flow Circuit
2. **Project URL**: apex-flow-circuit (or your preferred URL)
3. **Short description**: A high-speed hoverboarding racing game with gravity-defying mechanics
4. **Classification**: Game
5. **Kind of project**: HTML (if you want web playable) or Downloadable
6. **Pricing**: Up to you (Free, Paid, or Name your price)
7. **Uploads**: 
   - Click "Upload files"
   - Upload each ZIP file
   - For each file, set the platform:
     - Windows: Check "Windows"
     - Linux: Check "Linux"
     - macOS: Check "macOS"
     - Web: Check "This file will be played in the browser"
   - Mark Windows as the default download

### Step 3: Game Page Settings

1. **Cover image**: Create a 630x500px cover image
2. **Screenshots**: Add 3-5 gameplay screenshots
3. **Description**: Write about your game features:
   - Gravity-defying hoverboard racing
   - Wall riding and rail grinding mechanics
   - Multiple character skins
   - Dynamic track generation
   - Multiplayer support (if enabled)

4. **Tags**: Add relevant tags like:
   - racing
   - 3d
   - arcade
   - multiplayer
   - godot

### Step 4: Web Build Settings (if using)

1. In the "Embed options" section:
   - **Viewport dimensions**: 1280x720 (or your preferred size)
   - **Fullscreen button**: Enable
   - **Mobile friendly**: Depends on your input system
   - **Shared memory**: Enable (for better performance)

### Step 5: Save and View

1. Click "Save & view page"
2. Test the web build if you uploaded one
3. Download and test the desktop builds

## Updating Your Game

When you need to update:

1. Export new builds from Godot
2. Create new ZIP files
3. On your itch.io game page, go to "Edit game"
4. Delete old files and upload new ones
5. Save changes

## Marketing Tips

1. **Create a trailer**: Record gameplay footage
2. **Social media**: Share on Twitter/X with #indiedev #godotengine
3. **Game jams**: Consider entering relevant game jams
4. **Community**: Engage with players in comments

## Troubleshooting

### Web Build Issues
- If the game doesn't load, check browser console for errors
- Enable SharedArrayBuffer in itch.io embed settings
- Test in multiple browsers

### Download Issues
- Ensure all required files are in the ZIP
- Test downloads on different systems
- Consider code signing for Windows (reduces antivirus warnings)

## Next Steps

1. Complete the game's main features
2. Add proper UI/UX polish
3. Create marketing materials
4. Consider Steam release later 