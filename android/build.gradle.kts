allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 1. Calculer le nouveau chemin à partir du répertoire du projet (plus sûr)
val newBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // 2. Assigner le répertoire de build de chaque sous-projet
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 3. Tâche de nettoyage
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}