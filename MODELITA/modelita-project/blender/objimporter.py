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
