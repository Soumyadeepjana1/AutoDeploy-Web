
pipeline {
    agent any

    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        skipDefaultCheckout(true)
    }

    environment {
        // Docker Hub
        DOCKERHUB_USER    = 'soumyadeep7872'
        IMAGE_NAME        = 'autodeploy-web'
        DOCKERHUB_CRED_ID = 'dockerhub-credentials'

        // GitOps Repository
        GITOPS_REPO       = 'https://github.com/Soumyadeepjana1/autodeploy-web-gitops.git'
        GITOPS_CRED_ID    = 'github-gitops-credentials'
        GITOPS_BRANCH     = 'master'

        // IMPORTANT: Actual filename in GitHub
        DEPLOY_FILE       = 'deployment.yml'
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

        // 3. Validate Application Files
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

                        echo "Docker image pushed successfully!"
                    '''
                }
            }
        }

        // 6. Update GitOps Repository
        stage('Update GitOps Repo') {
            steps {
                dir('gitops') {

                    // Checkout GitOps Repository
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${GITOPS_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: "${GITOPS_REPO}",
                            credentialsId: "${GITOPS_CRED_ID}"
                        ]]
                    ])

                    // Update deployment.yml
                    sh '''
                        set -eu

                        echo "================================"
                        echo "Checking GitOps Repository"
                        echo "================================"

                        pwd
                        ls -la

                        test -f "$DEPLOY_FILE" || {
                            echo "ERROR: deployment.yml not found!"
                            exit 1
                        }

                        echo "Deployment file found!"

                        grep -qE '^[[:space:]]*image:[[:space:]]*' "$DEPLOY_FILE" || {
                            echo "ERROR: Image field not found!"
                            exit 1
                        }

                        echo "Old Docker image:"
                        grep -E '^[[:space:]]*image:' "$DEPLOY_FILE"

                        echo "Updating Docker image..."

                        sed -i -E \
                          "s|^([[:space:]]*image:[[:space:]]*).*$|\\1${FULL_IMAGE}|" \
                          "$DEPLOY_FILE"

                        echo "Verifying updated image..."

                        grep -Fq "image: ${FULL_IMAGE}" "$DEPLOY_FILE" || {
                            echo "ERROR: Image update failed!"
                            exit 1
                        }

                        echo "New Docker image:"
                        grep -F "image: ${FULL_IMAGE}" "$DEPLOY_FILE"

                        // This line is handled by shell below
                    '''

                    // Configure Git and push using Jenkins credentials
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${GITOPS_CRED_ID}",
                            usernameVariable: 'GH_USER',
                            passwordVariable: 'GH_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@autodeploy.local"

                            git add "$DEPLOY_FILE"

                            if git diff --cached --quiet; then
                                echo "No changes detected."
                                exit 0
                            fi

                            git commit -m "deploy: update Learnora image ${GIT_SHA}"

                            echo "Pushing changes to GitHub..."

                            ASKPASS="$(mktemp)"
                            trap 'rm -f "$ASKPASS"' EXIT

                            cat > "$ASKPASS" <<'EOF'
#!/bin/sh
case "$1" in
    *Username*) printf '%s\\n' "$GH_USER" ;;
    *Password*) printf '%s\\n' "$GH_TOKEN" ;;
esac
EOF

                            chmod 700 "$ASKPASS"

                            export GIT_ASKPASS="$ASKPASS"
                            export GIT_TERMINAL_PROMPT=0

                            git push origin "HEAD:${GITOPS_BRANCH}"

                            echo "GitOps repository updated successfully!"
                        '''
                    }
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
            GitOps Repository: ${env.GITOPS_REPO}
            GitOps Branch: ${env.GITOPS_BRANCH}
            Deployment File: ${env.DEPLOY_FILE}

            Argo CD will sync the changes.
            =====================================
            """
        }

        failure {
            echo """
            =====================================
            PIPELINE FAILED!
            Check Jenkins Console Output.
            =====================================
            """
        }
    }
}
