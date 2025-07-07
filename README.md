# Timelog
TimeLog is a simple app for keeping track of time.

This is a reimplementation of [gtimelog](https://github.com/gtimelog/gtimelog) in [godot](https://godotengine.org/)

## Install

There is no installation necassary. Just download the [latest release](https://github.com/FailedCode/timelog/releases/latest) and start it up.

## Usage

  * Start the application
  * When you finished a task, enter a description of what you have done
  * When you were out for lunch or took a break, add `**` to the description

## Build it yourself

  * Download [godot](https://godotengine.org/)
  * Clone this repository to your machine
  * Start Godot and add the repository to your projects
  * Open the Project for Editing
  * Choose `Project -> Export...`
  * Select the preset that is right for your needs and click `Export Project...`

### Windows

You may need to Download [rcedit-x64.exe](https://github.com/electron/rcedit/releases)

### The minimal-size version

By default, godot exports a lot of features for games such as 3D and Vulkan support. This makes
the exported executable about 93 MB - a little big for a UI only application.

`build/minimal_godot_profile.py` contains the necassary steps to build a template release version
that can be used to export a smaller executable. Please refer to this file if you like to build
a smaller application yourself.

## Known problems and shortcomings

- Timelog does not and will not deal with timezones, sorry
