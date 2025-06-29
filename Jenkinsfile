pipeline {
    agent any

    environment {
        HARBOR_REGISTRY = '192.168.49.1'
        HARBOR_PROJECT = 'encuestapp-prueba'
        HARBOR_CREDENTIALS_ID = 'harbor-robot-account'
        APP_NAME = 'encuestapp'

        KUBERNETES_MANIFESTS_REPO_URL = 'https://github.com/nimbusops1/encuestapp-k8s-infra.git'
        KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID = 'github-token-k8s'
        KUBERNETES_MANIFESTS_BRANCH = 'main'

        IMAGE_NAME = 'nimbus2025/encuestapp'
        // ❌ NO definimos FULL_IMAGE_NAME aquí
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', credentialsId: 'github-ssh-key-cod', url: 'https://github.com/nimbusops1/encuestapp-app-code.git'
            }
        }

        stage('Detect Deployment Environment') {
            steps {
                script {
                    def commitMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    echo "Commit message: ${commitMessage}"

                    if (commitMessage.contains("[deploy-dev]")) {
                        env.TARGET_ENV = "dev"
                    } else if (commitMessage.contains("[deploy-stg]")) {
                        env.TARGET_ENV = "stg"
                    } else if (commitMessage.contains("[deploy-prod]")) {
                        if (!commitMessage.contains("[approved]")) {
                            error("❌ Despliegue a producción requiere aprobación explícita con [approved].")
                        }
                        env.TARGET_ENV = "prod"
                    } else {
                        error("❌ No se especificó un entorno válido en el mensaje de commit. Usá [deploy-dev], [deploy-stg] o [deploy-prod].")
                    }

                    echo "✔️ Entorno de despliegue detectado: ${env.TARGET_ENV}"
                }
            }
        }

        stage('Build Application') {
            steps {
                echo '⚙️ Simulando la construcción de la aplicación...'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.TARGET_ENV}-${commitSha}"
                    env.FULL_IMAGE_NAME = "${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:${env.IMAGE_TAG}"

                    echo "🛠️ Construyendo imagen: ${env.FULL_IMAGE_NAME}"
                    sh "docker build -t ${env.FULL_IMAGE_NAME} ."
                }
            }
        }

        stage('Push Docker Image to Harbor') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.HARBOR_CREDENTIALS_ID,
                                                      passwordVariable: 'HARBOR_PASSWORD',
                                                      usernameVariable: 'HARBOR_USERNAME')]) {
                        sh "echo \$HARBOR_PASSWORD | docker login ${env.HARBOR_REGISTRY} --username \$HARBOR_USERNAME --password-stdin"
                        sh "docker push ${env.FULL_IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Update Kustomize Patch') {
    steps {
        script {
            def patchPath = "overlays/${env.TARGET_ENV}/patch-deployment.yaml"

            dir('kubernetes-manifests-repo-checkout') {
                git branch: "${env.KUBERNETES_MANIFESTS_BRANCH}",
                    credentialsId: "${env.KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID}",
                    url: "${env.KUBERNETES_MANIFESTS_REPO_URL}"

                echo "🔧 Actualizando patch con imagen: ${env.FULL_IMAGE_NAME}"

                sh """
                    sed -i "s|image: .*|image: ${env.FULL_IMAGE_NAME}|g" ${patchPath}
                """

                sh "git config user.email 'jenkins@yourcompany.com'"
                sh "git config user.name 'Jenkins CI Robot'"

                sh "git add ${patchPath}"
                sh "git commit -m '[Jenkins CI] Patch image tag to ${env.IMAGE_TAG} for ${env.TARGET_ENV}' || true"

                withCredentials([usernamePassword(credentialsId: env.KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID, usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh """
                        git remote set-url origin https://\$GITHUB_USER:\$GITHUB_TOKEN@github.com/nimbusops1/encuestapp-k8s-infra.git
                        git push origin ${env.KUBERNETES_MANIFESTS_BRANCH}
                    """
                }
            }
        }
    }
}
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo '❌ ¡El Pipeline Falló! Revisa la consola.'
        }
        success {
            echo '✅ ¡Pipeline completado exitosamente!'
        }
    }
}
