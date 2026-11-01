
pipeline {
    agent any

    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        // Docker Hub
        DOCKERHUB_USER    = 'soumyadeep7872'
        IMAGE_NAME        = 'autodeploy-web'
        DOCKERHUB_CRED_ID = 'dockerhub-credentials'

        // GitHub GitOps Repository
        GITOPS_REPO       = 'https://github.com/soumyadeepjana1/autodeploy-web-gitops.git'
        GITOPS_CRED_ID    = 'github-gitops-credentials'
        GITOPS_BRANCH     = 'master'

        DEPLOY_FILE       = 'deployment.yaml'
    }

    stages {

        // 1. Checkout Application Repository
        stage('Checkout App') {
            steps {
                checkout scm
            }
        }

        // 2. Generate Docker Image Tag
        stage('Set Image Tag') {
            steps {
                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.FULL_IMAGE =
                        "${DOCKERHUB_USER}/${IMAGE_NAME}:${env.GIT_SHA}"
                }

                echo "Docker Image: ${env.FULL_IMAGE}"
            }
        }

        // 3. Validate Website Files
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

        // 4. Build Docker Image
        stage('Docker Build') {
            steps {
                sh '''
                    set -eu
                    docker build -t "$FULL_IMAGE" .
                '''
            }
        }

        // 5. Push Image to Docker Hub
        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKERHUB_CRED_ID}",
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_PASS'
                    )
                ]) {
                    sh '''
                        set -eu

                        export DOCKER_CONFIG="$(mktemp -d)"

                        cleanup() {
                            docker logout >/dev/null 2>&1 || true
                            rm -rf "$DOCKER_CONFIG"
                        }

                        trap cleanup EXIT

                        echo "$DH_PASS" | docker login \
                            -u "$DH_USER" --password-stdin

                        docker push "$FULL_IMAGE"
                    '''
                }
            }
        }

        // 6. Update GitOps Repository
        stage('Update GitOps Repo') {
            steps {
                dir('gitops') {

                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${GITOPS_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: "${GITOPS_REPO}",
                            credentialsId: "${GITOPS_CRED_ID}"
                        ]]
                    ])

                    sh '''
                        set -eu

                        echo "Checking deployment.yaml..."

                        test -f "$DEPLOY_FILE"

                        grep -q '^[[:space:]]*image:' "$DEPLOY_FILE" || {
                            echo "ERROR: Image field not found!"
                            exit 1
                        }

                        echo "Updating Docker image..."

                        # Preserve existing YAML indentation
                        sed -i -E \
                          "s|^([[:space:]]*)image:.*$|\\1image: ${FULL_IMAGE}|" \
                          "$DEPLOY_FILE"

                        # Verify image update
                        if ! grep -Fq "image: ${FULL_IMAGE}" "$DEPLOY_FILE"; then
                            echo "ERROR: Docker image update failed!"
                            exit 1
                        fi

                        echo "Updated image:"
                        grep -F "image: ${FULL_IMAGE}" "$DEPLOY_FILE"

                        # Configure Git
                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@autodeploy.local"

                        git add "$DEPLOY_FILE"

                        # Commit only when changes exist
                        if git diff --cached --quiet; then
                            echo "No changes detected. Skipping commit."
                        else
                            git commit -m "deploy: update Learnora image ${GIT_SHA}"

                            git push origin HEAD:${GITOPS_BRANCH}
                        fi
                    '''
                }
            }
        }
    }

    // 7. Post Build Actions
    post {

        always {
            script {
                if (env.FULL_IMAGE?.trim()) {
                    sh "docker rmi '${env.FULL_IMAGE}' || true"
                }
            }
        }

        success {
            echo """
            =====================================
            LEANORA CI/CD PIPELINE SUCCESS!
            =====================================
            Docker Image: ${env.FULL_IMAGE}
            GitOps Branch: ${env.GITOPS_BRANCH}
            Argo CD will sync the changes.
            =====================================
            """
        }

        failure {
            echo """
            =====================================
            PIPELINE FAILED!
            Check Jenkins Console Output.
            ===================================== ......
            
            """
        }
    }
}
