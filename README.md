# Switcher

## Overview
Switcher is a macOS application that provides a category-based alternative to the standard Command (⌘) + Tab app switcher. Instead of organizing applications by recent usage, Switcher groups them by category, making it easier to find and switch between related applications.

## Features
- Triggered by Option + Tab
- Groups applications by categories:
  - Productivity (Office apps, Notes, etc.)
  - Development (IDEs, text editors, dev tools)
  - Communication (Slack, Teams, email clients)
  - Media (Music, video players, image editors)
  - Other (Miscellaneous applications)
- Runs in the background

## Requirements
- macOS 12.0 or later
- Accessibility permissions (required for keyboard shortcut monitoring)

## Installation
1. Clone the repository
2. Build using Xcode
3. Grant accessibility permissions when prompted

## Usage
1. Launch the application
2. Press Option + Tab to bring up the switcher
3. Use the mouse to select apps from different categories
4. Click on an app to switch to it

## Development
This project is built using:
- Swift
- SwiftUI
- macOS accessibility APIs

## Why Another App Switcher?
While the default Command + Tab switcher is great for quickly switching between recent applications, it can become cumbersome when you have many applications open. By organizing applications by category, Switcher makes it easier to find and switch to the application you need, especially in professional workflows where you might be using multiple tools for different purposes.

## License
MIT

