
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timeout(time: 20, unit: 'MINUTES')
        timestamps()
    }

    environment {
        DOCKERHUB_USER = 'soumyadeep7872'
        IMAGE_NAME = 'autodeploy-web'

        GITOPS_REPO = 'https://github.com/Soumyadeepjana1/autodeploy-web-gitops.git'
        GITOPS_BRANCH = 'master'
        DEPLOY_FILE = 'deployment.yml'
    }

    stages {

        stage('Checkout App') {
            steps {
                checkout scm
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.FULL_IMAGE = "${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }

                echo "Docker Image: ${FULL_IMAGE}"
            }
        }

        stage('Validate Files') {
            steps {
                sh '''
                    set -eu

                    test -f index.html
                    test -f style.css
                    test -f Dockerfile

                    echo "Website files validation successful!"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    set -eu

                    docker build -t "$FULL_IMAGE" .

                    echo "Docker image build successful!"
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_PASS'
                    )
                ]) {
                    sh '''
                        set -eu

                        DOCKER_CONFIG_DIR=$(mktemp -d)
                        export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"

                        cleanup() {
                            docker logout >/dev/null 2>&1 || true
                            rm -rf "$DOCKER_CONFIG_DIR"
                        }

                        trap cleanup EXIT

                        echo "$DH_PASS" | docker login \
                            -u "$DH_USER" \
                            --password-stdin

                        docker push "$FULL_IMAGE"

                        echo "Docker image pushed successfully!"
                    '''
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                dir('gitops') {
                    deleteDir()

                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-gitops-credentials',
                            url: 'https://github.com/Soumyadeepjana1/autodeploy-web-gitops.git'
                        ]]
                    ])

                    sh '''
                        set -eu

                        echo "Checking GitOps Repository"

                        test -f "$DEPLOY_FILE"

                        grep -qE '^[[:space:]]*image:[[:space:]]*' "$DEPLOY_FILE"

                        echo "Old Docker image:"
                        grep -E '^[[:space:]]*image:' "$DEPLOY_FILE"

                        echo "Updating Docker image..."

                        sed -i -E \
                            "s|^([[:space:]]*image:[[:space:]]*).*$|\\1${FULL_IMAGE}|" \
                            "$DEPLOY_FILE"

                        echo "Verifying updated image..."

                        grep -Fq "image: ${FULL_IMAGE}" "$DEPLOY_FILE"

                        echo "New Docker image:"
                        grep -F "image:" "$DEPLOY_FILE"
                    '''

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-gitops-credentials',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )
                    ]) {
                        sh '''
                            set -eu

                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@example.com"

                            if git diff --quiet -- "$DEPLOY_FILE"; then
                                echo "No GitOps changes to commit."
                            else
                                git add "$DEPLOY_FILE"

                                git commit -m "Update image to ${IMAGE_TAG}"

                                ASKPASS=$(mktemp)

                                trap 'rm -f "$ASKPASS"' EXIT

                                cat > "$ASKPASS" <<'EOF'
#!/bin/sh
case "$1" in
    *Username*) printf '%s\\n' "$GIT_USERNAME" ;;
    *Password*) printf '%s\\n' "$GIT_PASSWORD" ;;
    *) exit 1 ;;
esac
EOF

                                chmod +x "$ASKPASS"

                                GIT_ASKPASS="$ASKPASS" \
                                GIT_TERMINAL_PROMPT=0 \
                                git push origin "HEAD:${GITOPS_BRANCH}"

                                echo "GitOps repository updated successfully!"
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo '''
            =====================================
               PIPELINE SUCCESSFUL!
               Docker Image pushed.
               GitOps repository updated........
            =====================================
            '''
        }

        failure {
            echo '''
            =====================================
               PIPELINE FAILED!
               Check Jenkins Console Output..
            =====================================
            '''
        }

        always {
            script {
                if (env.FULL_IMAGE) {
                    sh '''
                        docker rmi "$FULL_IMAGE" || true
                    '''
                }
            }
        }
    }
}
