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

    stage('SonarQube - Scan code vulnerabilidades') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh "mvn sonar:sonar \
		              -Dsonar.projectKey=numeric-application \
		              -Dsonar.host.url=http://192.168.58.11:9000"
        }
        timeout(time: 2, unit: 'MINUTES') {
          script {
            waitForQualityGate abortPipeline: true
          }
        }
      }
    }

    // stage('Vulnerability Scan - Docker ') {
    //   steps {
    //     sh "mvn dependency-check:check"
    //   }
    //   post {
    //     always {
    //       dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    //     }
    //   }
    // }

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