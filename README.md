# PowerShell Tetris Game

This project is a simple Tetris game implemented in PowerShell. It utilizes Windows assemblies for key handling and UI rendering, making it a fun and educational project for those interested in scripting and game development with PowerShell.

## Prerequisites

- PowerShell 7 or later is required to run this script. You can download it from the [official PowerShell GitHub repository](https://github.com/PowerShell/PowerShell).

## Setup Instructions

1. **Download the Script**

   Download the `pstetris.ps1` script from the repository's.

2. **Navigate to the Download Location**

   Open your terminal and navigate to the directory where you downloaded the script:

   ```bash
   cd "%USERPROFILE%\Downloads\"
   ```
3. **Run the Script**

   Execute the script using PowerShell:

   ```bash
   pwsh -ExecutionPolicy Bypass -File .\pstetris.ps1
   ```

   Ensure you are using `pwsh` to invoke PowerShell 7 or later.

## Game Controls

- **Arrow Keys**: Move the blocks left, right, or down.
- **Up Arrow**: Rotate the blocks.
- **Enter**: Select menu items.

## Features

- **Random Block Generation**: Blocks are generated in random sizes and colors.
- **Score Tracking**: Keeps track of the current and best scores, storing the best score in the Windows Registry.
- **Simple UI**: Renders the game board using console graphics.
- **Background Music**: Plays the classic Tetris theme music in the background.

## Code Structure

- **Classes**:
  - `Size`: Represents the size of a block.
  - `Location`: Represents the location of a block on the game board.
  - `Block`: Handles block properties and behaviors such as movement and collision detection.
  - `Map`: Manages the game board and updates the game state.

- **Functions**:
  - `Show-Menu`: Displays the main menu and handles user input.

## Notes

- This script uses Windows-specific assemblies, so it is designed to run on Windows operating systems.
- The game may not perform optimally on systems with limited resources due to the use of console graphics.


Enjoy playing Tetris in PowerShell!
