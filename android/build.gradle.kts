allprojects {
    repositories {
        google()
        mavenCentral()
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

// NOTA: Anteriormente había aquí un hack de reflexión para forzar compileSdk=36
// en todos los subproyectos (incluidos plugins como file_picker), porque
// file_picker 8.3.7 traía compileSdk=34 hard-codeado en su propio build.gradle
// y eso no se puede sobreescribir desde el proyecto consumidor (Flutter no
// expone ningún mecanismo soportado para ello: FlutterPluginUtils.kt solo
// detecta el desajuste y sugiere subir compileSdk del módulo app, que ya
// estaba en 36). La causa raíz real era la versión del plugin: file_picker
// 11.0.0 ("Updated Android package to support AGP 9") ya declara un
// compileSdk compatible. Solución aplicada: actualizar file_picker a ^11.0.3
// en pubspec.yaml. Con eso este bloque ya no es necesario y se retira porque
// además era frágil (afterEvaluate puede ejecutarse después de que AGP ya
// congeló el AAR metadata en algunos casos).

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
