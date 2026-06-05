#ifndef MY_CLASS_H
#define MY_CLASS_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <vector>
#include <string>
#include <unordered_map>

using namespace godot;

class MyClass : public Node {
    GDCLASS(MyClass, Node)

private:
    // Example private members (customize as needed)
    std::string exampleString;
    int exampleInt;
    std::vector<std::string> exampleVector;

protected:
    static void _bind_methods();

public:
    MyClass();
    ~MyClass();

    // Godot 4 lifecycle method
    void _ready() override;

    // Example methods (customize as needed)
    void example_method(const String& param1, int param2);
    String get_example_string() const;
    void set_example_string(const String& value);
};

#endif // MY_CLASS_H
