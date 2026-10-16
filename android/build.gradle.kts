allprojects {
    repositories {
        google()
        maven { url = uri("https://repo1.maven.org/maven2") }
        mavenCentral()
    }
    // google_mobile_ads 7.x (the newest plugin the Flutter 3.35 web builder
    // can resolve) ships GMA SDK 24.9.0, which AdMob reports as out of date.
    // Force the current GMA SDK for every module, the plugin included, so an
    // incompatible API fails at compile time rather than at runtime.
    configurations.all {
        resolutionStrategy.force("com.google.android.gms:play-services-ads:25.5.0")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
