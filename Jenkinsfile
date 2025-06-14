// Define el pipeline completo
pipeline {
    // Define dónde se ejecutará el pipeline. 'any' significa en cualquier agente disponible.
    // Si tienes un agente específico o quieres usar un contenedor Docker para el build, lo definirías aquí.
    agent any

    // Define variables de entorno que serán usadas a lo largo del pipeline
    environment {
        // URL completa de tu registro Harbor (sin http/https)
        // EJEMPLO: 'harbor.yourcompany.com' o 'mi-harbor.local'
        HARBOR_REGISTRY =  '127.0.0.1:82' //'tu-dominio-harbor.com' // ¡CÁMBIALO! //--> tengo la direccion 127.0.0.1:82

        // Nombre del proyecto en Harbor donde se almacenará la imagen
        // EJEMPLO: 'my-app-project' o 'encuestapp'
        HARBOR_PROJECT = 'encuestapp-prueba' // ¡CÁMBIALO! --->proyecto de harbor

        // ID de las credenciales que crearemos en Jenkins para acceder a Harbor
        HARBOR_CREDENTIALS_ID = 'harbor-robot-account' // --> se configuro asi en la cred en jenkins

        // Nombre de tu aplicación (se usará para el nombre de la imagen Docker)
        APP_NAME = 'encuestapp'

        ///////// K8S //////
        environment {
        // ... (tus variables existentes de Harbor y APP_NAME) ...

        // --- Variables para el Repositorio de Manifiestos de Kubernetes ---
        // URL del repositorio Git donde están tus archivos de Kubernetes (ej. el repositorio 'kubernetes-manifests')
        // Si es privado y usas SSH, debe ser el formato SSH (ej. 'git@github.com:tu-usuario/kubernetes-manifests.git')
        KUBERNETES_MANIFESTS_REPO_URL = 'git@github.com:nimbusops1/k8s.git' //

        // ID de la credencial SSH que creaste en Jenkins para acceder a este repositorio de GitHub
        KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID = 'github-ssh-key-k8s' // tiene que ser privado

        // La rama de tu repositorio de manifiestos que Jenkins debe actualizar (generalmente 'main' o 'master')
        KUBERNETES_MANIFESTS_BRANCH = 'main' // ¡CÁMBIALO!

        // La ruta relativa al archivo deployment.yaml dentro de tu repositorio de manifiestos
        // EJEMPLO: 'k8s/deployment.yaml' si tienes un directorio 'k8s'
        KUBERNETES_DEPLOYMENT_FILE_PATH = 'k8s/deployment.yaml' // ¡CÁMBIALO!
    }
    }

    // Define las etapas de tu pipeline
    stages {
        // Etapa 1: Clonar el código fuente de GitHub
        stage('Checkout Source Code') {
            steps {
                // Clona el repositorio desde GitHub.
                // Asegúrate de que la rama sea la correcta (es "main", no master).
                // El ID 'github-token' es la credencial que Jenkins usa para acceder a tu repositorio.
                git branch: 'main', credentialsId: 'github-ssh-key-cod', url: 'https://github.com/nimbusops1/pipeline_prueba.git'
            }
        }

        // Etapa 2: Construir la Aplicación (dependiendo de tu tecnología)
        stage('Build Application') {
            steps {
                // Aquí es donde compilas tu código (Java, Node.js, Python, etc.)
                // Adapta esta sección a tu aplicación.
                // EJEMPLOS:
                // sh 'mvn clean install' // Para Java con Maven
                // sh 'npm install && npm run build' // Para Node.js
                // sh 'pip install -r requirements.txt' // Para Python (si tu app no tiene un build step)
                echo 'Simulando la construcción de la aplicación...'
                // Si tu Dockerfile copia el código fuente, este paso puede ser omitido aquí y solo en el Dockerfile.
                //ACA NO VA NADA SI TENEMOS UN DOCKERFILE EN LA RAIZ DEL REPO (SI LA TENEMOS!!!!!)
            }
        }

        // Etapa 3: Construir la Imagen Docker
        stage('Build Docker Image') {
            steps {
                script {
                    // Genera un tag único para la imagen usando el SHA del commit de Git (el id del commit de git se convierte en el tag de docker).
                    // Esto asegura que cada build tenga una imagen única.
                    def commitSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${commitSha}" // Ejemplo: f2b3c7d
                    env.FULL_IMAGE_NAME = "${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:${env.IMAGE_TAG}"

                    // Construye la imagen Docker.
                    // El '.' al final significa que el Dockerfile está en el directorio actual (la raíz del repo).
                    // Asegúrate de que tu Dockerfile esté presente y sea válido.
                    sh "docker build -t ${env.FULL_IMAGE_NAME} ."
                    echo "Imagen Docker construida: ${env.FULL_IMAGE_NAME}"
                }
            }
        }

        // Etapa 4: Empujar la Imagen Docker a Harbor
        stage('Push Docker Image to Harbor') {
            steps {
                script {
                    // Utiliza las credenciales de Harbor que creamos en Jenkins
                    // `withCredentials` inyecta el nombre de usuario y la contraseña como variables de entorno
                    // que `docker login` puede usar con `--password-stdin`.
                    withCredentials([usernamePassword(credentialsId: env.HARBOR_CREDENTIALS_ID,
                                                    passwordVariable: 'HARBOR_PASSWORD',
                                                    usernameVariable: 'HARBOR_USERNAME')]) {
                        // Autentica con Harbor
                        sh "echo ${HARBOR_PASSWORD} | docker login ${env.HARBOR_REGISTRY} --username ${HARBOR_USERNAME} --password-stdin"
                        // Empuja la imagen al registro de Harbor
                        sh "docker push ${env.FULL_IMAGE_NAME}"
                        echo "Imagen Docker ${env.FULL_IMAGE_NAME} empujada a Harbor."
                    }
                }
            }
        }

        // Etapa 5: Actualizar Manifiestos de Kubernetes (Para ArgoCD - Pasos Siguientes)
        // Esta etapa la detallaremos más cuando hablemos de ArgoCD.
        // Por ahora, solo es un placeholder.
       // stage('Update Kubernetes Manifests (for ArgoCD)') {
         //   steps {
           //     echo "Esta etapa actualizará los manifiestos de Kubernetes en un repositorio Git separado."
             //   echo "ArgoCD detectará este cambio para desplegar la nueva imagen."
               // echo "Imagen a usar: ${env.FULL_IMAGE_NAME}"
           // }
        //}
    //}
    // Etapa 5: Actualizar Manifiestos de Kubernetes (Para ArgoCD)
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    echo "Clonando el repositorio de manifiestos de Kubernetes..."
                    // El comando 'dir' es importante para trabajar en un subdirectorio.
                    // Esto evita conflictos con el repositorio de tu aplicación principal.
                    dir('kubernetes-manifests-repo-checkout') { // Puedes elegir otro nombre de directorio temporal
                        // Clonar el repositorio de manifiestos de Kubernetes
                        // Asegúrate de que las variables de entorno para este repo estén definidas al inicio del Jenkinsfile
                        // (KUBERNETES_MANIFESTS_REPO_URL, KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID, KUBERNETES_MANIFESTS_BRANCH)

                        git branch: "${env.KUBERNETES_MANIFESTS_BRANCH}",
                            credentialsId: "${env.KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID}", // ID de la credencial SSH que creaste para GitHub
                            url: "${env.KUBERNETES_MANIFESTS_REPO_URL}"

                        echo "Actualizando el tag de la imagen en ${env.KUBERNETES_DEPLOYMENT_FILE_PATH} con: ${env.FULL_IMAGE_NAME}"

                        // --- ¡IMPORTANTE! Ajusta esta línea 'sh "sed -i ..."' a tu sistema operativo del agente Jenkins y el formato de tu YAML ---
                        // `sed` es una herramienta de línea de comandos para editar texto.
                        // La expresión regular 's|...' busca y reemplaza el texto.
                        // 'image: ${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:.*'
                        //      Busca la línea que comienza con 'image:', luego el nombre de tu imagen (que ya incluye el registro y proyecto),
                        //      y '. *' es un comodín que coincide con CUALQUIER tag actual que tenga la imagen.
                        // 'image: ${env.FULL_IMAGE_NAME}|g'
                        //      Lo reemplaza con el nombre completo de la imagen que acabas de construir y empujar, que incluye el nuevo tag (SHA del commit).
                        //
                        // --- Variaciones de 'sed -i' según el sistema operativo del agente Jenkins: ---
                        // Para Linux (o dentro de un contenedor Docker Linux):
                        sh "sed -i 's|image: ${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:.*|image: ${env.FULL_IMAGE_NAME}|g' ${env.KUBERNETES_DEPLOYMENT_FILE_PATH}"
                        // Para macOS (se necesita una cadena vacía después de -i):
                        // sh "sed -i '' 's|image: ${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:.*|image: ${env.FULL_IMAGE_NAME}|g' ${env.KUBERNETES_DEPLOYMENT_FILE_PATH}"
                        // --------------------------------------------------------------------------------------------------------------------

                        echo "Configurando Git para el commit..."
                        // Configurar la identidad del usuario Git para el commit que Jenkins hará
                        sh "git config user.email 'jenkins@yourcompany.com'" // Puedes usar tu propio email
                        sh "git config user.name 'Jenkins CI Robot'" // Puedes usar otro nombre

                        echo "Añadiendo y commiteando los cambios..."
                        // Añade el archivo modificado al área de staging de Git
                        sh "git add ${env.KUBERNETES_DEPLOYMENT_FILE_PATH}"
                        // Hace el commit. '|| true' al final es para evitar que el pipeline falle si no hay cambios que commitear
                        // (por ejemplo, si la imagen no cambió, aunque esto es menos probable con un tag SHA).
                        sh "git commit -m '[Jenkins CI] Update ${env.APP_NAME} image to version ${env.IMAGE_TAG}' || true"

                        echo "Empujando los cambios al repositorio de manifiestos..."
                        // Empuja los cambios a la rama remota.
                        sh "git push origin ${env.KUBERNETES_MANIFESTS_BRANCH}"

                        echo "Manifiestos de Kubernetes actualizados y empujados."
                    }
                }
            }
        }

    // Define acciones a realizar después de que el pipeline finaliza
    post {
        // Siempre limpia el workspace del Job después de la ejecución
        always {
            cleanWs()
        }
        // Muestra un mensaje si el pipeline falla
        failure {
            echo '¡El Pipeline Falló! Revisa la Salida de la Consola para detalles.'
        }
        // Muestra un mensaje si el pipeline es exitoso
        success {
            echo '¡El Pipeline se completó exitosamente!'
        }
    }
}
}
