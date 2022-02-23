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
        withDockerRegistry([url: "https://991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application",credentialsId: "ecr:us-east-1:agusitoawsecr"]) {
          sh 'printenv'
          sh 'docker build -t 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:"build_"$GIT_COMMIT""$BUILD_NUMBER"" .'
          sh 'docker push 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:"build_"$GIT_COMMIT""$BUILD_NUMBER"'
        }
      }
    }
  }
}