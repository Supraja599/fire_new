allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("com.google.mlkit:barcode-scanning:17.3.0")
            force("androidx.camera:camera-core:1.4.1")
            force("androidx.camera:camera-camera2:1.4.1")
            force("androidx.camera:camera-lifecycle:1.4.1")
            force("androidx.camera:camera-view:1.4.1")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val targetEnum = project.extensions.findByName("android")?.let { android ->
            val javaVersion = (android as? com.android.build.gradle.BaseExtension)?.compileOptions?.targetCompatibility
            when (javaVersion) {
                JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                else -> null
            }
        } ?: org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8

        compilerOptions {
            jvmTarget.set(targetEnum)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
