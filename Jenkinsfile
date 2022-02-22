## Docker Build and Push Stage
## replace  siddharth67 with your dockerhub username

pipeline {
  agent any
  environment {
        AWS_ACCOUNT_ID="991256897826"
        registryCredential = 'agusito.aws.credentials'
        AWS_DEFAULT_REGION="us-east-1" 
        IMAGE_REPO_NAME="agusito"
        REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
    }

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

    stage('Unit Tests - JUnit and Jacoco') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry('https://" + REGISTRY, "ecr:us-east-1:" + registryCredential') {
          sh 'printenv'
          sh 'docker build -t 991256897826.dkr.ecr.us-east-1.amazonaws.com/agusito:""$GIT_COMMIT"" .'
          sh 'docker push 991256897826.dkr.ecr.us-east-1.amazonaws.com/agusito:""$GIT_COMMIT""'
        }
      }
    }
  }
}
