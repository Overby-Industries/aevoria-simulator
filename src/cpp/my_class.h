#ifndef MY_CLASS_H
#define MY_CLASS_H

#include <gdextension_interface.h>
#include <godot.hpp>
#include <Godot.hpp>
#include <Node.hpp>
#include <vector>
#include <string>
#include <unordered_map>

using namespace godot;

/// @brief A template class for Godot 4.0+ using GDNative.
/// Replace `MyClass` with your class name (e.g., `AlarmSystem`, `CorruptionDetector`).
class MyClass : public Node {
    GODOT_CLASS(MyClass, Node)

private:
    // Example private members (customize as needed)
    std::string exampleString;
    int exampleInt;
    std::vector<std::string> exampleVector;

public:
    /// @brief Registers methods and properties with Godot.
    static void _register_methods();

    /// @brief Constructor.
    MyClass();

    /// @brief Destructor.
    ~MyClass();

    /// @brief Initialization (called by Godot when the node is added to the scene).
    void _init();

    // Example methods (customize as needed)
    void example_method(const String& param1, int param2);
    String get_example_string() const;
    void set_example_string(const String& value);
};

#endif // MY_CLASS_H