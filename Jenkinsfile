pipeline {
    agent any
    parameters {
        choice(
            name: 'BUILD_ENVIRONMENT',
            choices: ['dev_env', 'prod_env'],
            description: 'interesting stuff' )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply --auto-approve', 'destroy --auto-approve'],
            description: 'destroy stuff' )
      }
    stages {
        stage('Build Terraform') {
            steps {
            lastChanges since: 'LAST_SUCCESSFUL_BUILD', format:'SIDE',matching: 'LINE'
                withVault(vaultSecrets: [[path: 'secret/build/k8s/vault', secretValues: [[vaultKey: 'role_id'], [vaultKey: 'secret_id']]]]) {
                     script {
                         sh '''
                         sed -i "s/docker_build_env/${BUILD_ENVIRONMENT}/g" Dockerfile ./scripts/*.sh
                         sed -i "s/docker_state_env/${ACTION}/g" Dockerfile
                         sed -i "s/vault_role_env/${role_id}/g" ./scripts/*.sh
                         sed -i "s/vault_secret_id_env/${secret_id}/g" ./scripts/*.sh
                         sed -i "s/vault_host_env/${vault_host}/g" ./scripts/*.sh
                         '''
                          docker.build('tf/tf', '-f Dockerfile ./')
                     }
                }
            }
        }
        stage('Remove docker images') {
            steps {
                script {
                    sh 'docker rmi tf/tf:latest --force'
                }
            //build job: 'mlncsPushDocker'
            }
        }
    }
    post {
            // Clean after build
        always {
            notifyEvents level: 'notice', message: '$JOB_NAME-$BUILD_NUMBER with $BUILD_ENVIRONMENT $ACTION has status <b>$BUILD_STATUS</b>', title: '$BUILD_TAG - Message test', token: 'v6iTIzNqn81rpl9okATGndzYwF5nWeaw'
            cleanWs()
        }
    }
}

