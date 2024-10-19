#!/bin/bash

# MODELITA Installation Script
# Version: 0.2
# License: FSL-1.1-MIT

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check for Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Installing Docker..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Install Docker on Linux
            sudo apt-get update
            sudo apt-get install -y docker.io docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            print_success "Docker installed successfully!"
            print_status "Please log out and log back in for group changes to take effect."
        else
            print_error "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
            exit 1
        fi
    else
        print_success "Docker is already installed!"
    fi
}

# Create project structure and files
create_project() {
    PROJECT_DIR="modelita-project"
    print_status "Creating MODELITA project directory..."
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR

    # Create required directories
    print_status "Creating required directories..."
    mkdir -p models
    mkdir -p symbols
    mkdir -p blender

    # Create Dockerfile
    print_status "Creating Dockerfile..."
    cat > Dockerfile << 'EOL'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgis \
    wget \
    sudo \
    python3 \
    python3-pip \
    libcairo2 \
    libglib2.0-0 \
    libpango1.0-0 \
    libgtk2.0-0 \
    openssl \
    libgmp-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install the latest Racket forcibly into /usr/local
RUN wget https://mirror.racket-lang.org/installers/8.14/racket-8.14-x86_64-linux-cs.sh \
    && chmod +x racket-8.14-x86_64-linux-cs.sh \
    && yes | ./racket-8.14-x86_64-linux-cs.sh --in-place --dest /usr/local \
    && rm racket-8.14-x86_64-linux-cs.sh

# Add Racket to the PATH
ENV PATH="/usr/local/racket/bin:${PATH}"


# Now you can run your raco pkg install
RUN raco pkg show db || raco pkg install --auto db

RUN mkdir -p /app/modelita/symbols \
    && mkdir -p /app/modelita/models \
    && mkdir -p /app/modelita/blender

WORKDIR /app/modelita

COPY modelita.rkt /app/modelita/
COPY blender/objimporter.py /app/modelita/blender/
COPY LICENSE.md /app/modelita/

USER postgres
RUN /etc/init.d/postgresql start && \
    psql -c "CREATE DATABASE gisdb;" && \
    psql -d gisdb -c "CREATE EXTENSION postgis;" && \
    psql -c "ALTER USER postgres PASSWORD 'modelita123';" && \
    echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf

USER root
RUN echo '#!/bin/bash\n\
service postgresql start\n\
echo "PostgreSQL started"\n\
echo "Starting DrRacket..."\n\
drracket\n\
' > /app/modelita/start.sh && \
chmod +x /app/modelita/start.sh

EXPOSE 5432

ENTRYPOINT ["/app/modelita/start.sh"]
EOL

    # Create docker-compose.yml
    print_status "Creating docker-compose.yml..."
    cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  modelita:
    build: .
    ports:
      - "5432:5432"
    volumes:
      - ./models:/app/modelita/models
      - ./symbols:/app/modelita/symbols
      - ./blender:/app/modelita/blender
    environment:
      - POSTGRES_PASSWORD=modelita123
      - POSTGRES_HOST_AUTH_METHOD=trust
EOL

    # Create LICENSE
    print_status "Creating LICENSE..."
    cat > LICENSE.md << 'EOL'
# Functional Source License, Version 1.1, MIT Future License

## Abbreviation

FSL-1.1-MIT

## Notice

Copyright 2024 Daniel Motilla Monreal

## Terms and Conditions

### Licensor ("We")

The party offering the Software under these Terms and Conditions.

### The Software

The "Software" is each version of the software that we make available under
these Terms and Conditions, as indicated by our inclusion of these Terms and
Conditions with the Software.

### License Grant

Subject to your compliance with this License Grant and the Patents,
Redistribution and Trademark clauses below, we hereby grant you the right to
use, copy, modify, create derivative works, publicly perform, publicly display
and redistribute the Software for any Permitted Purpose identified below.

### Permitted Purpose

A Permitted Purpose is any purpose other than a Competing Use. A Competing Use
means making the Software available to others in a commercial product or
service that:

1. substitutes for the Software;

2. substitutes for any other product or service we offer using the Software
   that exists as of the date we make the Software available; or

3. offers the same or substantially similar functionality as the Software.

Permitted Purposes specifically include using the Software:

1. for your internal use and access;

2. for non-commercial education;

3. for non-commercial research; and

4. in connection with professional services that you provide to a licensee
   using the Software in accordance with these Terms and Conditions.

### Patents

To the extent your use for a Permitted Purpose would necessarily infringe our
patents, the license grant above includes a license under our patents. If you
make a claim against any party that the Software infringes or contributes to
the infringement of any patent, then your patent license to the Software ends
immediately.

### Redistribution

The Terms and Conditions apply to all copies, modifications and derivatives of
the Software.

If you redistribute any copies, modifications or derivatives of the Software,
you must include a copy of or a link to these Terms and Conditions and not
remove any copyright notices provided in or with the Software.

### Disclaimer

THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES OF FITNESS FOR A PARTICULAR
PURPOSE, MERCHANTABILITY, TITLE OR NON-INFRINGEMENT.

IN NO EVENT WILL WE HAVE ANY LIABILITY TO YOU ARISING OUT OF OR RELATED TO THE
SOFTWARE, INCLUDING INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES,
EVEN IF WE HAVE BEEN INFORMED OF THEIR POSSIBILITY IN ADVANCE.

### Trademarks

Except for displaying the License Details and identifying us as the origin of
the Software, you have no right under these Terms and Conditions to use our
trademarks, trade names, service marks or product names.

## Grant of Future License

We hereby irrevocably grant you an additional license to use the Software under
the MIT license that is effective on the second anniversary of the date we make
the Software available. On or after that date, you may use the Software under
the MIT license, in which case the following will apply:

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOL

    # Create modelita.rkt
    print_status "Creating modelita.rkt..."
    cat > modelita.rkt << 'EOL'
#lang racket
(require db)
(require math/matrix)

; Connect to PostGIS database
(define db-conn
  (postgresql-connect #:database "gisdb"
                      #:user "postgres"
                      #:password "modelita123"
                      #:server "localhost"
                      #:port 5432))

; Define our base symbols
(define base-symbols '(up down left right forward backward a b select start 
                      rotate-x+ rotate-x- rotate-y+ rotate-y- rotate-z+ rotate-z-
                      push pop))

; Custom symbol storage (will store user-defined symbols)
(define custom-symbols (make-hash))

; Define our current state
(define current-position (list 0 0 0))
(define current-shape '())
(define position-stack '())
(define rotation-matrix (matrix [[1 0 0]
                               [0 1 0]
                               [0 0 1]]))
(define matrix-stack '())

; Maximum recursion depth (to prevent infinite recursion)
(define max-recursion-depth 10)

; Helper functions for 3D operations and matrix manipulation
(define (matrix-multiply m1 m2)
  (matrix* m1 m2))

(define (vec->matrix vec)
  (matrix [[(first vec)]
           [(second vec)]
           [(third vec)]]))

(define (matrix->vec mat)
  (list (matrix-ref mat 0 0)
        (matrix-ref mat 1 0)
        (matrix-ref mat 2 0)))

(define (rotate-x angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [rx (matrix [[1.0 0.0  0.0]
                     [0.0 c    (- s)]
                     [0.0 s    c]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix rx))))

(define (rotate-y angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [ry (matrix [[c     0.0  s]
                     [0.0    1.0  0.0]
                     [(- s)  0.0  c]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix ry))))

(define (rotate-z angle)
  (let* ([c (cos angle)]
         [s (sin angle)]
         [rz (matrix [[c    (- s) 0.0]
                     [s     c    0.0]
                     [0.0   0.0  1.0]])])
    (set! rotation-matrix (matrix-multiply rotation-matrix rz))))

(define (apply-rotation vec)
  (let* ([vec-matrix (vec->matrix vec)]
         [rotated (matrix-multiply rotation-matrix vec-matrix)])
    (matrix->vec rotated)))

(define (move-3d x y z)
  (let ([movement (apply-rotation (list x y z))])
    (set! current-position 
          (list (+ (first current-position) (first movement))
                (+ (second current-position) (second movement))
                (+ (third current-position) (third movement))))))

(define (push-state)
  (set! position-stack (cons current-position position-stack))
  (set! matrix-stack (cons rotation-matrix matrix-stack)))

(define (pop-state)
  (when (and (not (null? position-stack)) (not (null? matrix-stack)))
    (set! current-position (car position-stack))
    (set! position-stack (cdr position-stack))
    (set! rotation-matrix (car matrix-stack))
    (set! matrix-stack (cdr matrix-stack))))

(define (add-vertex)
  (set! current-shape (cons current-position current-shape)))

; Process a symbol with recursion depth control
(define (process-symbol symbol depth)
  (when (<= depth max-recursion-depth)
    (cond
      [(hash-has-key? custom-symbols symbol)
       (for-each (λ (s) (process-symbol s (add1 depth)))
                 (hash-ref custom-symbols symbol))]
      [else
       (case symbol
         [(up) (move-3d 0 1 0)]
         [(down) (move-3d 0 -1 0)]
         [(left) (move-3d -1 0 0)]
         [(right) (move-3d 1 0 0)]
         [(forward) (move-3d 0 0 1)]
         [(backward) (move-3d 0 0 -1)]
         [(rotate-x+) (rotate-x (/ pi 2))]
         [(rotate-x-) (rotate-x (/ pi -2))]
         [(rotate-y+) (rotate-y (/ pi 2))]
         [(rotate-y-) (rotate-y (/ pi -2))]
         [(rotate-z+) (rotate-z (/ pi 2))]
         [(rotate-z-) (rotate-z (/ pi -2))]
         [(push) (push-state)]
         [(pop) (pop-state)]
         [(a) (add-vertex)]
         [(b) (set! current-shape '())]
         [(select) (printf "Current position: ~a\n" current-position)]
         [(start) (save-obj "output.obj")
                 (printf "Shape saved to models/output.obj\n")])])))

; Modified function to save the current shape as an .obj file in the models directory
(define (save-obj filename)
  (let ([full-path (build-path "models" filename)])
    (with-output-to-file full-path
      (lambda ()
        (for ([vertex (reverse current-shape)]
              [index (in-naturals 1)])
          (printf "v ~a ~a ~a\n" 
                  (first vertex) 
                  (second vertex) 
                  (third vertex)))
        (printf "f")
        (for ([index (in-range 1 (add1 (length current-shape)))])
          (printf " ~a" index))
        (newline))
      #:exists 'replace)))

; Function to define a new symbol
(define (define-symbol name commands)
  (hash-set! custom-symbols name commands)
  (printf "Symbol '~a' defined\n" name))

; Function to save a symbol to file
(define (save-symbol-to-file name commands filename)
  (with-output-to-file (string-append "symbols/" filename ".sym")
    (lambda ()
      (write commands))
    #:exists 'replace))

; Function to save a symbol
(define (save-symbol name)
  (when (hash-has-key? custom-symbols name)
    (save-symbol-to-file name 
                        (hash-ref custom-symbols name)
                        (symbol->string name))
    (printf "Symbol '~a' saved to file\n" name)))

; Function to load symbol definitions from file
(define (load-symbol-from-file filename)
  (with-input-from-file (string-append "symbols/" filename ".sym")
    read))

; Function to load a symbol
(define (load-symbol filename)
  (let ([name (string->symbol filename)]
        [commands (load-symbol-from-file filename)])
    (define-symbol name commands)
    (printf "Symbol '~a' loaded from file\n" name)))

; Enhanced main loop
(define (main-loop)
  (display "Enter command (symbol or define/save/load/quit): ")
  (flush-output)
  (let ([input (read)])
    (cond
      [(eq? input 'quit)
       (displayln "Exiting program.")]
      [(eq? input 'define)
       (display "Enter new symbol name: ")
       (let ([name (read)])
         (display "Enter commands (as list): ")
         (let ([commands (read)])
           (define-symbol name commands)))
       (main-loop)]
      [(eq? input 'save)
       (display "Enter symbol name to save: ")
       (save-symbol (read))
       (main-loop)]
      [(eq? input 'load)
       (display "Enter symbol filename to load: ")
       (load-symbol (symbol->string (read)))
       (main-loop)]
      [(or (member input base-symbols)
           (hash-has-key? custom-symbols input))
       (process-symbol input 0)
       (main-loop)]
      [else
       (displayln "Invalid command. Please try again.")
       (main-loop)])))

; Create required directories if they don't exist
(make-directory* "symbols")
(make-directory* "models")

; Start the program
(main-loop)

; Close database connection
(disconnect db-conn)
EOL

    # Create objimporter.py
    print_status "Creating Blender importer script..."
    cat > blender/objimporter.py << 'EOL'
import bpy
import os
import glob

# Define the model directory
model_dir = '/change/dis/frikin/dir/'

# Global variable to store debug info
debug_info = []

class OBJECT_OT_reload_obj(bpy.types.Operator):
    """Reload OBJ files from the specified directory"""
    bl_idname = "object.reload_obj"
    bl_label = "Reload OBJ"
    bl_options = {'REGISTER', 'UNDO'}
    
    def log(self, message):
        """Add message to debug info"""
        global debug_info
        debug_info.append(message)
        print(message)  # Still print for terminal if available
    
    def cleanup_scene(self):
        """Basic cleanup of the scene"""
        self.log("Starting cleanup...")
        
        # Only try to set object mode if there's an active object
        if bpy.context.active_object:
            if bpy.context.active_object.mode != 'OBJECT':
                bpy.ops.object.mode_set(mode='OBJECT')
        
        # Deselect all first
        bpy.ops.object.select_all(action='DESELECT')
        
        # Delete objects one by one
        for obj in bpy.data.objects:
            obj.select_set(True)
            bpy.ops.object.delete()
        
        # Clear meshes
        for mesh in bpy.data.meshes:
            bpy.data.meshes.remove(mesh)
        
        # Force update
        bpy.context.view_layer.update()
        self.log("Cleanup completed")

    def execute(self, context):
        global debug_info
        debug_info = []  # Clear previous debug info
        
        self.log("="*30)
        self.log("STARTING RELOAD OPERATION")
        self.log("="*30)
        
        # Print some debug info
        self.log(f"Script location: {os.path.abspath(__file__)}")
        self.log(f"Current working directory: {os.getcwd()}")
        self.log(f"Model directory: {model_dir}")
        
        # Check if directory exists
        if not os.path.exists(model_dir):
            msg = f"Directory does not exist: {model_dir}"
            self.log(msg)
            self.report({'ERROR'}, msg)
            return {'CANCELLED'}
        
        # List all files in directory
        self.log("\nFiles in directory:")
        for file in os.listdir(model_dir):
            self.log(f"  {file}")
        
        # Clean up scene
        self.cleanup_scene()
        
        # Get OBJ files
        obj_files = [f for f in os.listdir(model_dir) if f.lower().endswith('.obj')]
        self.log(f"\nFound {len(obj_files)} OBJ files:")
        for obj in obj_files:
            self.log(f"  {obj}")
        
        if not obj_files:
            msg = f"No OBJ files found in: {model_dir}"
            self.log(msg)
            self.report({'WARNING'}, msg)
            return {'CANCELLED'}
        
        # Import each OBJ file
        for obj_file in obj_files:
            full_path = os.path.join(model_dir, obj_file)
            abs_path = os.path.abspath(full_path)
            self.log(f"\nTrying to import: {abs_path}")
            
            try:
                bpy.ops.wm.obj_import(filepath=abs_path)
                self.log(f"Successfully imported: {obj_file}")
            except Exception as e:
                msg = f"Error importing {obj_file}: {str(e)}"
                self.log(msg)
                self.report({'ERROR'}, msg)
        
        self.log("\nFinal scene contents:")
        for obj in bpy.data.objects:
            self.log(f"  {obj.name}")
        
        context.scene.debug_index = len(debug_info) - 1  # Show latest message
        return {'FINISHED'}

class OBJECT_PT_reload_obj_panel(bpy.types.Panel):
    """Creates a Panel in the 3D View N-panel"""
    bl_label = "OBJ Reloader"
    bl_idname = "OBJECT_PT_reload_obj_panel"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "My Tools"
    
    def draw(self, context):
        layout = self.layout
        
        # Add reload button
        row = layout.row()
        row.operator(OBJECT_OT_reload_obj.bl_idname)
        
        # Add directory info
        box = layout.box()
        box.label(text="Directory:")
        box.label(text=model_dir)
        
        # Add debug info
        if debug_info:
            box = layout.box()
            box.label(text="Debug Info:")
            
            # Add a scrollable area for debug info
            row = box.row()
            col = row.column()
            
            for line in debug_info[-10:]:  # Show last 10 lines
                col.label(text=line)

def register():
    bpy.types.Scene.debug_index = bpy.props.IntProperty(default=0)
    bpy.utils.register_class(OBJECT_OT_reload_obj)
    bpy.utils.register_class(OBJECT_PT_reload_obj_panel)

def unregister():
    del bpy.types.Scene.debug_index
    bpy.utils.unregister_class(OBJECT_PT_reload_obj_panel)
    bpy.utils.unregister_class(OBJECT_OT_reload_obj)

if __name__ == "__main__":
    register()
EOL

    # Create README.md
    print_status "Creating README..."
    cat > README.md << 'EOL'
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
EOL

    # Initialize Git repository
    print_status "Initializing Git repository..."
    git init
    cat > .gitignore << 'EOL'
# IDE and editor files
.vscode/
.idea/
*.swp

# Generated files
models/*.obj

# Local environment
.env
EOL
    git add .
    git commit -m "Initial MODELITA project setup"
}

# Main installation
main() {
    print_status "Starting MODELITA installation..."
    
    # Check for Docker
    check_docker
    
    # Create project
    create_project
    
    if [ $? -eq 0 ]; then
        print_success "MODELITA installation completed successfully!"
        print_status "Next steps:"
        echo "1. Install Blender from https://www.blender.org/"
        echo "2. cd modelita-project"
        echo "3. docker-compose up --build"
        echo ""
        print_status "To start using MODELITA:"
        echo "1. Wait for the Docker container to start"
        echo "2. Open Blender and configure the objimporter.py script"
        echo "3. Begin creating 3D models with MODELITA!"
    else
        print_error "Installation failed. Please check the error messages above."
    fi
}

# Run main installation
main
