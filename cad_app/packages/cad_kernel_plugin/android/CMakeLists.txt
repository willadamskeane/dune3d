cmake_minimum_required(VERSION 3.22.1)

project(cad_kernel_plugin VERSION 0.0.1 LANGUAGES CXX)

# Build the shared library for OCCT and ShapeOp wrappers
add_library(
    occt_cad
    SHARED
    src/main/cpp/occt_wrapper.cpp
    src/main/cpp/shapeop_wrapper.cpp
)

# Set C++17 standard
set_target_properties(occt_cad PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

# Define export symbol
target_compile_definitions(occt_cad PRIVATE OCCT_CAD_EXPORTS)

# Include directories
# TODO: Add actual OCCT and ShapeOp include directories when integrating
# target_include_directories(occt_cad PRIVATE
#     ${OCCT_INCLUDE_DIR}
#     ${SHAPEOP_INCLUDE_DIR}
# )

# Link libraries
# TODO: Link actual OCCT and ShapeOp libraries when integrating
# target_link_libraries(occt_cad
#     ${OCCT_LIBRARIES}
#     ${SHAPEOP_LIBRARIES}
# )

# Android log library
find_library(log-lib log)
target_link_libraries(occt_cad ${log-lib})

# Symbol visibility
set_target_properties(occt_cad PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)
