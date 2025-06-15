pipeline {
    agent any

    environment {
        HARBOR_REGISTRY = '127.0.0.1:82'
        HARBOR_PROJECT = 'encuestapp-prueba'
        HARBOR_CREDENTIALS_ID = 'harbor-robot-account'
        APP_NAME = 'encuestapp'

        KUBERNETES_MANIFESTS_REPO_URL = 'https://github.com/nimbusops1/k8s.git'
        KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID = 'github-token-k8s'
        KUBERNETES_MANIFESTS_BRANCH = 'main'
        KUBERNETES_DEPLOYMENT_FILE_PATH = 'deployment.yaml'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', credentialsId: 'github-ssh-key-cod', url: 'https://github.com/nimbusops1/pipeline_prueba.git'
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
                    env.IMAGE_TAG = "${commitSha}"
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
                    dir('kubernetes-manifests-repo-checkout') {
                        git branch: "${env.KUBERNETES_MANIFESTS_BRANCH}",
                            credentialsId: "${env.KUBERNETES_MANIFESTS_REPO_CREDENTIALS_ID}",
                            url: "${env.KUBERNETES_MANIFESTS_REPO_URL}"

                        sh "sed -i 's|image: ${env.HARBOR_REGISTRY}/${env.HARBOR_PROJECT}/${env.APP_NAME}:.*|image: ${env.FULL_IMAGE_NAME}|g' ${env.KUBERNETES_DEPLOYMENT_FILE_PATH}"

                        sh "git config user.email 'jenkins@yourcompany.com'"
                        sh "git config user.name 'Jenkins CI Robot'"

                        sh "git add ${env.KUBERNETES_DEPLOYMENT_FILE_PATH}"
                        sh "git commit -m '[Jenkins CI] Update ${env.APP_NAME} image to version ${env.IMAGE_TAG}' || true"

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
            echo '¡El Pipeline Falló! Revisa la consola.'
        }
        success {
            echo '¡Pipeline completado exitosamente!'
        }
    }
}
