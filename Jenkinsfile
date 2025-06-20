pipeline {
    agent any

    environment {
        HARBOR_REGISTRY = '192.168.49.1'
        HARBOR_PROJECT = 'encuestapp-prueba'
        HARBOR_CREDENTIALS_ID = 'harbor-robot-account'
        APP_NAME = 'encuestapp'

        KUBERNETES_MANIFESTS_REPO_URL = 'https://github.com/nimbusops1/k8s.git'
        KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID = 'github-token-k8s'
        KUBERNETES_MANIFESTS_BRANCH = 'main'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', credentialsId: 'github-ssh-key-cod', url: 'https://github.com/nimbusops1/pipeline_prueba.git'
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
                echo 'Simulando la construcción de la aplicación...'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.TARGET_ENV}-${commitSha}"
                    env.FULL_IMAGE_NAME = "${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:${env.IMAGE_TAG}"

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

        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    def manifestPath = "overlays/${env.TARGET_ENV}/deployment.yaml"

                    dir('kubernetes-manifests-repo-checkout') {
                        git branch: "${env.KUBERNETES_MANIFESTS_BRANCH}",
                            credentialsId: "${env.KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID}",
                            url: "${env.KUBERNETES_MANIFESTS_REPO_URL}"

                        // Actualiza la imagen en el deployment.yaml del entorno correcto
                        sh "sed -i 's|image: .*|image: ${env.FULL_IMAGE_NAME}|g' ${manifestPath}"

                        sh "git config user.email 'jenkins@yourcompany.com'"
                        sh "git config user.name 'Jenkins CI Robot'"

                        sh "git add ${manifestPath}"
                        sh "git commit -m '[Jenkins CI] Update ${env.APP_NAME} image to ${env.IMAGE_TAG} for ${env.TARGET_ENV}' || true"

                        withCredentials([usernamePassword(credentialsId: 'github-token-k8s', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                            sh """
                                git remote set-url origin https://\$GITHUB_USER:\$GITHUB_TOKEN@github.com/nimbusops1/k8s.git
                                git push origin main
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
