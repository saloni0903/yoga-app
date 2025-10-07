// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = rootProject.file("../build")

subprojects {
    project.buildDir = rootProject.buildDir.resolve(project.name)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}