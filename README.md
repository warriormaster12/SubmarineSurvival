# Submarine Survival

## Table of Contents
1. [Importing a Project](#importing-a-project)
2. [Project Structure](#project-structure)

## Importing a Project
- [Download Godot 4.2-beta 4](https://godotengine.org/article/dev-snapshot-godot-4-2-beta-4/)
  - scroll down to "Downloads" section
    ![Screenshot from 2023-11-03 23-29-56](https://github.com/warriormaster12/SubmarineSurvival/assets/33091666/091d3689-0e89-470d-b5fd-b9ac3525e7fa)
- clone the repository
- open godot and click "import" button on the top right corner
  ![image](https://github.com/warriormaster12/SubmarineSurvival/assets/33091666/ff04e478-1308-4fab-9a65-befd5549ccf1)
- find a directory where you have cloned the project and select "project.godot" file to import the project
### Optional but really recommended setting to enable for scripting
in godot editor, go to Editor->Editor Settings->Completion and enable "Add type hints". The text editor will automatically add type hints for built-in functions such as ```_ready()```, ```_process``` and ```_physics_process```
![Screenshot from 2023-11-03 23-36-30](https://github.com/warriormaster12/SubmarineSurvival/assets/33091666/ec7306f0-4ddc-4733-8f44-0ffc5e0bbc8b)


## Project Structure
```
- assets  #for storing source files that were created with software such as gimp, krita, audacity, blender, substance painter, flstudio etc.
- game_objects  #assets that are game ready, essentially prefabs
- scripts  #stores code that can be used by game_objects
- levels
```
### File Formats
- audio: wav, ogg
- models: gltf, textures separately to make sure that github doesn't block files that are over 100mb in size.
- textures: png, dds, jpg

  
