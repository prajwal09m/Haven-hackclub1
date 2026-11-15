@tool
extends EditorScript

func _run():
	var root = get_editor_interface().get_edited_scene_root()

	if root == null:
		print("No scene open!")
		return

	var meshes = []
	collect_meshes(root, meshes)

	var count = 0

	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue

		if mesh_instance.mesh is ArrayMesh or mesh_instance.mesh is PrimitiveMesh:
			var body = StaticBody3D.new()
			body.name = "GeneratedCollision"

			var collision = CollisionShape3D.new()
			collision.shape = mesh_instance.mesh.create_trimesh_shape()

			if collision.shape == null:
				body.free()
				continue

			mesh_instance.add_child(body)
			body.owner = root

			body.add_child(collision)
			collision.owner = root

			count += 1

	print("Generated collisions for ", count, " meshes!")


func collect_meshes(node: Node, result: Array):
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)

		collect_meshes(child, result)
