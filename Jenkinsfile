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

    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
    }

    stage('SonarQube - SAST') {
      steps {
        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=spring-boot-numeric-application -Dsonar.host.url=http://localhost:9000 -Dsonar.login=1dd591dc4a47c332cfbca4d4a78b8705e73cbb64"
      }
    }

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([url: "https://991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application",credentialsId: "ecr:us-east-1:agusitoawsecr"]) {
          sh 'printenv'
          sh 'docker build -t 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:""$GIT_COMMIT"" .'
          sh 'docker push 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:""$GIT_COMMIT""'
        }
      }
    }
    stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh "sed -i 's#replace#991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh "kubectl apply -f k8s_deployment_service.yaml"
        }
      }
    }
  }
}