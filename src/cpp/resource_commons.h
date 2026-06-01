#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class ResourceCommons : public Node {
    GDCLASS(ResourceCommons, Node)

private:
    // Add your member variables here

protected:
    static void _bind_methods();

public:
    ResourceCommons();
    ~ResourceCommons();

    void _ready() override;
    void _process(double delta) override;
};

} // namespace godot