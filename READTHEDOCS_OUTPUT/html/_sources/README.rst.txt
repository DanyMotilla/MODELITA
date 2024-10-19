MODELITA v0.2 Command Cheatsheet
================================

Movement Commands
----------------
::

    up      - Move up
    down    - Move down
    left    - Move left
    right   - Move right
    forward - Move forward
    backward - Move backward

Rotation Commands
----------------
::

    rotate-x+  - Rotate +90° X-axis
    rotate-x-  - Rotate -90° X-axis
    rotate-y+  - Rotate +90° Y-axis
    rotate-y-  - Rotate -90° Y-axis
    rotate-z+  - Rotate +90° Z-axis
    rotate-z-  - Rotate -90° Z-axis

Shape Editing
-------------
::

    a      - Add vertex at current position
    b      - Clear shape
    select - Print current position
    start  - Save shape to OBJ file

State Management
---------------
::

    push   - Save position/rotation
    pop    - Restore position/rotation

Symbol Management
----------------
::

    define - Create new symbol
    save   - Save symbol for later
    load   - Load saved symbol

Example Usage
------------
::

    define
    my-symbol
    (up right forward)

    save
    my-symbol

    load
    my-symbol

Quick Copy Raw Commands
----------------------
::

    up down left right forward backward rotate-x+ rotate-x- rotate-y+ rotate-y- rotate-z+ rotate-z- a b select start push pop define save load
