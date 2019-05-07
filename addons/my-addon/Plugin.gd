extends EditorSpatialGizmoPlugin

const MyCustomSpatial = preload("res://addons/my-addon/MyCustomSpatial.gd")

func _init():
    create_material("main", Color(1,0,0))
    create_handles_material("handles")

func has_gizmo(spatial):
    return spatial is MyCustomSpatial

func redraw(gizmo):
    gizmo.clear()

    var spatial = gizmo.get_spatial_node()

    var lines = PoolVector3Array()

    lines.push_back(Vector3(0, 1, 0))
    lines.push_back(Vector3(0, spatial.my_custom_value, 0))

    var handles = PoolVector3Array()

    handles.push_back(Vector3(0, 1, 0))
    handles.push_back(Vector3(0, spatial.my_custom_value, 0))

    gizmo.add_lines(lines, get_material("main", gizmo), false)
    gizmo.add_handles(handles, get_material("handles", gizmo))

# you should implement the rest of handle-related callbacks
# (get_handle_name(), get_handle_value(), commit_handle()...)