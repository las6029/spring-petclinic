pipeline {
    agent any
    
    tools{
        maven "M3"
        jdk "JDK21"
        
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerCredential')
        REGION = "ap-northeast-2"
        AWS_CREDENTIALS_NAME = "AWSCredentials"
    }
    
    stages {
        stage('Git Clone') {
            steps {
                echo 'Git Clone'
                git url: 'https://github.com/las6029/spring-petclinic.git',
                    branch: 'main'
            }
            post {
                success {
                    echo 'Git Clone Success'
                }
                failure {
                    echo 'Git clone Fail'
                }
            }
        }
        // Maven build 작업
        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package' // Test error 무시
            }
           
        }

        // Dovker Image 생성
        stage('Docker Image Build') {
            steps {
                echo 'Docker Image Build'

                dir("${env.WORKSPACE}") {
                   sh '''
                      docker build -t spring-petclinic:$BUILD_NUMBER .
                      docker tag spring-petclinic:$BUILD_NUMBER las6029/spring-petclinic:latest
                      '''
                        
                }
            }
        }

        // Docker Iamge Push

        stage('Docker Image Push') {
            steps {
                sh '''
                   echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                   docker push las6029/spring-petclinic:latest
                   '''
            }
        }

        //Remove Docker Image

        stage('Remove Docker Image') {
            steps {
                sh '''
                docker rmi spring-petclinic:$BUILD_NUMBER
                docker rmi las6029/spring-petclinic:latest
                '''
            }
        }
        stage('Upload S3') {
            steps {
                echo "Upload to S3"
                dir("${env.WORKSPACE}") {
                    sh '''
                        which zip || apt update && apt install -y zip
                        zip -r scripts.zip ./scripts appspec.yml
                    '''
                    withAWS(region:"${REGION}",credentials:"${AWS_CREDENTIALS_NAME}"){
                        s3Upload(file:"scripts.zip", bucket:"project1-bucket-jss")
                    }
                    sh 'rm -rf ./scripts.zip' 
                }
            }    
        }
        
        stage('Codedeploy Workload') {
            steps {
               echo "create Codedeploy group"   
               withAWS(region: "${REGION}", credentials: "${AWS_CREDENTIALS_NAME}") {
                sh '''
                    aws deploy create-deployment-group \
                    --application-name project1-application \
                    --auto-scaling-groups project1-auto-scaling-group \
                    --deployment-group-name project1-production-in_place-${BUILD_NUMBER} \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --service-role-arn arn:aws:iam::491085389788:role/project1-code-deploy-service-role
                    '''
                echo "Codedeploy Workload"   
                sh '''
                    aws deploy create-deployment --application-name project1-application \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --deployment-group-name project1-production-in_place-${BUILD_NUMBER} \
                    --s3-location bucket=project1-bucket-jss,bundleType=zip,key=deploy.zip
                    '''
            }
                    sleep(10) // sleep 10s
            }
    }
}

}
