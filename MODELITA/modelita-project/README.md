# MODELITA v0.2

## Overview
MODELITA is a Domain-Specific Language (DSL) for 3D modeling, integrating Racket, PostGIS, and Blender.

## Directory Structure
- models/: Generated 3D models
- symbols/: Custom MODELITA symbols
- blender/: Blender-related files
- modelita.rkt: Main MODELITA program
- Dockerfile & docker-compose.yml: Container configuration
- LICENSE: FSL-1.1-MIT license

## Quick Start
1. Make sure Docker is installed
2. Run: `docker-compose up --build`
3. Install Blender from https://www.blender.org/
4. Configure Blender with the provided script in blender/objimporter.py

## License
Licensed under FSL-1.1-MIT. See LICENSE file for details.
