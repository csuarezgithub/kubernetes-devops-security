@Library('slack') _

pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:${GIT_COMMIT}"
    applicationURL = "http://192.168.58.11"
    applicationURI = "/increment/99"
  }

  stages {

    stage('Testing Slack') {
      steps {
        sh 'exit 0'
      }
    }

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
      // post {
      //   always {
      //     junit 'target/surefire-reports/*.xml'
      //     jacoco execPattern: 'target/jacoco.exec'
      //   }
      // }
    }

    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      // post {
      //   always {
      //     pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      //   }
      // }
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

    stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
          // "Dependency Scan": {
          //   sh "mvn dependency-check:check"
          // },
          "Trivy Scan": {
            sh "bash trivy-docker-image-scan.sh"
          },
          "OPA Conftest": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
      }
    }

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([url: "https://991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application",credentialsId: "ecr:us-east-1:agusitoawsecr"]) {
          sh 'printenv'
          sh 'sudo docker build -t 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:""$GIT_COMMIT"" .'
          sh 'docker push 991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:""$GIT_COMMIT""'
        }
      }
    }

    stage('Vulnerability Scan - Kubernetes') {
      steps {
        parallel(
          "OPA Scan": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          },
          "Kubesec Scan": {
            sh "bash kubesec-scan.sh"
          },
          "Trivy Scan": {
            withDockerRegistry([url: "https://991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application",credentialsId: "ecr:us-east-1:agusitoawsecr"]){
            //sh "aws ecr get-login-password --region us-east-1 |docker login --username AWS --password-stdin 991256897826.dkr.ecr.us-east-1.amazonaws.com"
            sh "bash trivy-k8s-scan.sh"
          }
          }
        )
      }
    }

    // stage('Vulnerability Scan - Kubernetes') {
    //   steps {
    //     parallel(
    //       "OPA Scan": {
    //         sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
    //       },
    //       "Kubesec Scan": {
    //         sh "bash kubesec-scan.sh"
    //       }
    //     )
    //   }
    // }
    
    // stage('Vulnerability Scan - Kubernetes') {
    //   steps {
    //     sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
    //   }
    // }

    // stage('Kubernetes Deployment - DEV') {
    //   steps {
    //     withKubeConfig([credentialsId: 'kubeconfig']) {
    //       sh "sed -i 's#replace#991256897826.dkr.ecr.us-east-1.amazonaws.com/spring-boot-devops-numeric-application:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
    //       sh "kubectl apply -f k8s_deployment_service.yaml"
    //     }
    //   }
    // }
    stage('K8S Deployment - DEV') {
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment.sh"
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment-rollout-status.sh"
            }
          }
        )
      }
    }

    stage('Integration Tests - DEV') {
      steps {
        script {
          try {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash integration-test.sh"
            }
          } catch (e) {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "kubectl -n default rollout undo deploy ${deploymentName}"
            }
            throw e
          }
        }
      }
    }

    stage('OWASP ZAP - DAST') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh 'bash zap.sh'
        }
      }
    }

    stage('Prompte to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }

    stage('K8S CIS Benchmark') {
      steps {
        script {

          parallel(
            "Master": {
              sh "bash cis-master.sh"
            },
            "Etcd": {
              sh "bash cis-etcd.sh"
            },
            "Kubelet": {
              sh "bash cis-kubelet.sh"
            }
          )

        }
      }
    }

  }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
      publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report'])

      // Use sendNotifications.groovy from shared library and provide current build result as parameter    
      sendNotification currentBuild.result
    }
  }
}