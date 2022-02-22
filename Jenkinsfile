## Docker Build and Push Stage
## replace  siddharth67 with your dockerhub username

pipeline {
  agent any

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
        withDockerRegistry([credentialsId: "agusito.aws.credentials", url: "991256897826.dkr.ecr.us-east-1.amazonaws.com/agusito"]) {
          sh 'printenv'
          sh 'docker build -t 991256897826.dkr.ecr.us-east-1.amazonaws.com/agusito:""$GIT_COMMIT"" .'
          sh 'docker push 991256897826.dkr.ecr.us-east-1.amazonaws.com/agusito:""$GIT_COMMIT""'
        }
      }
    }
  }
}