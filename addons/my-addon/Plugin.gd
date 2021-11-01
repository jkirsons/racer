# MyCustomEditorPlugin.gd

@tool
extends EditorPlugin

const MyCustomGizmoPlugin = preload("res://addons/my-addon/MyCustomGizmoPlugin.gd")

var gizmo_plugin = MyCustomGizmoPlugin.new()

func _enter_tree():
	print("Plugin - enter tree")
	add_spatial_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	print("Plugin - exit tree")
	remove_spatial_gizmo_plugin(gizmo_plugin)

func get_plugin_name():
	return "Rotation Plugin"
