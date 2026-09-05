allprojects {
    layout.buildDirectory.set(
        rootProject.layout.buildDirectory
            .dir("../../build")
            .get(),
    )
}

subprojects {
    layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
