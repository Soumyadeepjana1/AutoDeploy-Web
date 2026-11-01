// ============================================================
//  AutoDeploy-Web — Learnora Website CI/CD Pipeline
//  Flow: Git Push -> Jenkins build -> Docker Hub -> GitOps -> Argo CD -> Kubernetes
// ============================================================

pipeline {
    agent any

    // Build options — timeout, no parallel builds, keep old logs limited
    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    // Environment variables (no secrets here — creds come from Jenkins Credential Store)
    environment {
        DOCKERHUB_USER    = 'soumyadeep7872'                                          // <-- CHANGE if needed
        IMAGE_NAME        = 'autodeploy-web'                                          // Docker Hub image name
        DOCKERHUB_CRED_ID = 'dockerhub-credentials'                                   // Jenkins credential ID for Docker Hub
        GITOPS_REPO       = 'https://github.com/soumyadeep7872/autodeploy-web-gitops.git' // <-- CHANGE to your GitOps repo URL
        GITOPS_CRED_ID    = 'github-gitops-credentials'                               // Jenkins credential ID for GitOps repo
        DEPLOY_FILE       = 'deployment.yaml'                                         // file to update inside GitOps repo
    }

    stages {

        // ---- Stage 1: Checkout application code (index.html, style.css, Dockerfile) ----
        stage('Checkout App') {
            steps {
                checkout scm
            }
        }

        // ---- Stage 2: Generate a unique image tag from the Git commit SHA ----
        stage('Set Image Tag') {
            steps {
                script {
                    // short commit SHA (first 7 chars) — e.g. a1b2c3d
                    env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.FULL_IMAGE = "${DOCKERHUB_USER}/${IMAGE_NAME}:${env.GIT_SHA}"
                }
                echo "Image tag for this build: ${env.FULL_IMAGE}"
            }
        }

        // ---- Stage 3: Basic validation of HTML and CSS files ----
        stage('Validate Files') {
            steps {
                sh '''
                    echo "==> Checking required files exist..."
                    test -f index.html || (echo "index.html MISSING" && exit 1)
                    test -f style.css  || (echo "style.css MISSING"  && exit 1)
                    echo "==> index.html size: $(wc -c < index.html) bytes"
                    echo "==> style.css  size: $(wc -c < style.css)  bytes"
                    echo "==> Validation OK"
                '''
            }
        }

        // ---- Stage 4: Build Docker image using the commit SHA tag ----
        stage('Docker Build') {
            steps {
                sh "docker build -t ${env.FULL_IMAGE} ."
            }
        }

        // ---- Stage 5: Login to Docker Hub and push the image ----
        stage('Push to Docker Hub') {
            steps {
                // Credentials are injected at runtime — never stored in code
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKERHUB_CRED_ID,
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push "$FULL_IMAGE"
                        docker logout
                    '''
                }
            }
        }

        // ---- Stage 6: Checkout GitOps repo and update image tag in deployment.yaml ----
        stage('Update GitOps Repo') {
            steps {
                dir('gitops') {
                    // Clone the GitOps repo with credentials
                    checkout([$class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: env.GITOPS_REPO,
                            credentialsId: env.GITOPS_CRED_ID
                        ]]
                    ])

                    // Replace the image tag in deployment.yaml with the new commit SHA tag
                    sh '''
                        echo "==> Updating ${DEPLOY_FILE} with image: ${FULL_IMAGE}"
                        sed -i "s|image: .*autodeploy-web:.*|image: ${FULL_IMAGE}|g" ${DEPLOY_FILE}
                        echo "==> Current image line:"
                        grep "image:" ${DEPLOY_FILE}
                    '''

                    // Commit & push ONLY if there is an actual change (no unnecessary commits)
                    sh '''
                        git config user.name  "Jenkins CI"
                        git config user.email "jenkins@autodeploy.local"
                        git add ${DEPLOY_FILE}
                        if git diff --cached --quiet; then
                            echo "==> No change in image tag. Skipping commit."
                        else
                            echo "==> Committing new image tag ${FULL_IMAGE}"
                            git commit -m "deploy: update autodeploy-web image to ${FULL_IMAGE}"
                            git push origin main
                        fi
                    '''
                }
            }
        }

        // NOTE: Jenkins does NOT deploy to Kubernetes.
        // Argo CD watches this GitOps repo and auto-syncs the new image. That's it!
    }

    // ---- Post-build actions: always run, plus success/failure handling ----
    post {
        always {
            // Clean up local image to save disk space on the Jenkins agent
            sh "docker rmi ${env.FULL_IMAGE} || true"
        }
        success {
            echo "✅ Build SUCCESS — image ${env.FULL_IMAGE} pushed. Argo CD will sync shortly."
        }
        failure {
            echo "❌ Build FAILED — check the stage logs above. GitOps repo was NOT changed on failure."
        }
    }
}
