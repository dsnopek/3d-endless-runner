Spatialize
==========

**Spatialize** is a set of utilities for converting flat-screen 3D games into
immersive or semi-immersive XR experiences.

First Steps
-----------

The first step is just getting your project to start in OpenXR mode.

In "Project Settings":

- Check the **XR** -> **OpenXR** -> **Enabled** checkbox
- Check the **XR** -> **Shaders** -> **Enabled** checkbox
- Restart the Godot editor

Add the following nodes to your main scene:

- `XROrigin3D`
- `XRCamera3D` as a child of the `XROrigin3D` node
- If you want to use controllers or hand-tracking, add two `XRController3D` nodes as
  children of the `XROrigin3D` node, and set their "Tracker" properties to "left_hand"
  and "right_hand"

Add an instance of the `res://addons/sgxr/start_xr.tscn` scene to your main scene.
This will automatically 

Rendering
---------

When converting a flat-screen game to XR, there are multiple approaches that
you could take to rendering:

- **Immersive**: the 3D game world surrounds the player completely - they are
  _inside_ the game.
- **Portal:** the game world renders on the other side of a flat "portal",
  with either the real world room or a non-playable virtual environment
	surrounding the player.
- **Volume:** the game world renders within a 3D volume, which appears to
  float in their real world room, or in a non-playable virtual environment.

### Immersive



### Portal or Volume


Input
-----

