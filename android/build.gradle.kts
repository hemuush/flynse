// Top-level build file where you can add configuration options common to all sub-projects/modules.
// This file primarily configures settings for all modules and defines repositories.

// Note: The 'plugins' block for declaring versions is usually in settings.gradle.kts
// and the 'plugins' block for applying plugins is in app/build.gradle.kts.
// This top-level build.gradle.kts usually doesn't have a 'plugins' block.

// Configuration for all projects
allprojects {
    repositories {
        // Google's Maven repository for Android artifacts
        google()
        // Maven Central repository for general dependencies
        mavenCentral()
    }
}

// Define a new build directory at the root project level, one level up from the current directory.
// This is typical for Flutter projects to place Android build artifacts alongside other platform builds.
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// For each subproject (e.g., ':app'), set its build directory within the new root build directory.
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensures that all subprojects are evaluated only after the ':app' module has been evaluated.
// This is important to ensure proper dependency resolution, especially in multi-module projects.
subprojects {
    project.evaluationDependsOn(":app")
}

// Register a 'clean' task to delete the root build directory.
// This helps ensure a clean build by removing all generated files from the global build directory.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
