#include "my_class.h"
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

/**
 * @brief Bind methods and properties so they are visible to Godot.
 * 
 * This function is called automatically by Godot during engine initialization.
 * Use ClassDB::bind_method() to expose C++ methods to GDScript.
 */
void MyClass::_bind_methods() {
    ClassDB::bind_method(D_METHOD("example_method", "param1", "param2"), &MyClass::example_method);
    ClassDB::bind_method(D_METHOD("get_example_string"), &MyClass::get_example_string);
    ClassDB::bind_method(D_METHOD("set_example_string", "value"), &MyClass::set_example_string);

    // Expose exampleString as a property
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "example_string"), "set_example_string", "get_example_string");
}

/**
 * @brief Constructor.
 * 
 * Called when the object is instantiated. Initialize internal state here.
 */
MyClass::MyClass() {
    exampleString = "default";
    exampleInt = 0;
    exampleVector.clear();
}

/**
 * @brief Destructor.
 * 
 * Called when the object is freed. Clean up resources here if needed.
 */
MyClass::~MyClass() {
    // Cleanup if necessary
}

/**
 * @brief Called when the node enters the scene tree.
 * 
 * This replaces _init() from Godot 3. Use this for setup that depends on the scene.
 */
void MyClass::_ready() {
    UtilityFunctions::print("MyClass is ready!");
}

/**
 * @brief Example method callable from GDScript.
 * 
 * @param param1 A Godot String parameter.
 * @param param2 An integer parameter.
 */
void MyClass::example_method(const String& param1, int param2) {
    UtilityFunctions::print("example_method called with: ", param1, " and ", param2);
}

/**
 * @brief Getter for exampleString.
 * 
 * @return String The current value of exampleString.
 */
String MyClass::get_example_string() const {
    return String(exampleString.c_str());
}

/**
 * @brief Setter for exampleString.
 * 
 * @param value The new value to assign.
 */
void MyClass::set_example_string(const String& value) {
    exampleString = value.utf8().get_data();
}
