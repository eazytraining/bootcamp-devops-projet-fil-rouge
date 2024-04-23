/* import shared library. */
@Library('ulrich-shared-library')_

pipeline {
    environment {
        IMAGE_NAME = "ic-webapp"
        APP_CONTAINER_PORT = "8080"
        DOCKERHUB_ID = "choco1992"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
        ANSIBLE_IMAGE_AGENT = "registry.gitlab.com/robconnolly/docker-ansible:latest"
    }
    agent none
    stages {
       stage('Build image') {
           agent any
           steps {
              script {
                sh 'docker build --no-cache -f ./sources/app/${DOCKERFILE_NAME} -t ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ./sources/app'

              }
           }
       }
       stage('Scan Image with  SNYK') {
            agent any
            environment{
                SNYK_TOKEN = credentials('snyk_token')
            }
            steps {
                script{
                    sh '''
                    echo "Starting Image scan ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ..."
                    echo There is Scan result :
                    SCAN_RESULT=$(docker run --rm -e SNYK_TOKEN=$SNYK_TOKEN -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/app snyk/snyk:docker snyk test --docker $DOCKERHUB_ID/$IMAGE_NAME:$IMAGE_TAG --json ||  if [[ $? -gt "1" ]];then echo -e "Warning, you must see scan result \n" ;  false; elif [[ $? -eq "0" ]]; then   echo "PASS : Nothing to Do"; elif [[ $? -eq "1" ]]; then   echo "Warning, passing with something to do";  else false; fi)
                    echo "Scan ended"
                    '''
                }
            }
       }
       stage('Run container based on builded image') {
          agent any
          steps {
            script {
              sh '''
                  echo "Cleaning existing container if exist"
                  docker ps -a | grep -i $IMAGE_NAME && docker rm -f ${IMAGE_NAME}
                  docker run --name ${IMAGE_NAME} -d -p $APP_EXPOSED_PORT:$APP_CONTAINER_PORT  ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG       
                  sleep 5
              '''
             }
          }
       }
       stage('Test image') {
           agent any
           steps {
              script {
                sh '''
                   curl -I http://${HOST_IP}:${APP_EXPOSED_PORT} | grep -i "200"
                '''
              }
           }
       }
       stage('Clean container') {
          agent any
          steps {
             script {
               sh '''
                   docker stop $IMAGE_NAME
                   docker rm $IMAGE_NAME
               '''
             }
          }
       }

       stage ('Login and Push Image on docker hub') {
          agent any
          steps {
             script {
               sh '''
                   echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_ID --password-stdin
                   docker push ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
               '''
             }
          }
       }

       stage ('Prepare ansible environment') {
          agent any
          environment {
            VAULT_KEY = credentials('vault_key')
            PRIVATE_KEY = credentials('private_key')
          }          
          steps {
             script {
               sh '''
                  echo $VAULT_KEY > vault.key
                  echo $PRIVATE_KEY > id_rsa
                  chmod 600 id_rsa
               '''
             }
          }
       }

      stage('Deploy application ') {
        agent { docker { image 'registry.gitlab.com/robconnolly/docker-ansible:latest'  } }
        stages {
            stage ("Install Ansible role dependencies") {
                steps {
                    script {
                        sh 'echo launch ansible-galaxy install -r roles/requirement.yml if needed'
                    }
                }
            }

            stage ("Ping  targeted hosts") {
                steps {
                    script {
                        sh '''
                            apt update -y
                            apt install sshpass -y 
                            export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                            ansible all -m ping --private-key id_rsa  -l prod
                        '''
                    }
                }
            }

            stage ("Check all playbook syntax") {
                steps {
                    script {
                        sh '''
                            export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                            ansible-lint -x 306 sources/ansible-ressources/playbooks/* || echo passing linter
                            echo ${GIT_BRANCH}                                         
                        '''
                    }
                }
            }

            stage ("Deploy in PRODUCTION") {
                when { expression { GIT_BRANCH == 'origin/main'} }                
                stages {
                    stage ("PRODUCTION - Install Docker on all hosts") {
                        steps {
                            script {
                                sh '''
                                    export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                                    ansible-playbook sources/ansible-ressources/playbooks/install-docker.yml --vault-password-file vault.key --private-key id_rsa -l odoo_server,pg_admin_server
                                '''

                                
                                
                            }
                        }
                    }

                    stage ("PRODUCTION - Deploy pgadmin") {
                        steps {
                            script {
                                sh '''
                                    export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-pgadmin.yml --vault-password-file vault.key --private-key id_rsa -l pg_admin
                                '''
                            }
                        }
                    }
                    stage ("PRODUCTION - Deploy odoo") {
                        steps {
                            script {
                                sh '''
                                    export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-odoo.yml --vault-password-file vault.key --private-key id_rsa -l odoo
                                '''
                            }
                        }
                    }

                    stage ("PRODUCTION - Deploy ic-webapp") {
                        steps {
                            script {
                                sh '''
                                    export ANSIBLE_CONFIG=$(pwd)/sources/ansible-ressources/ansible.cfg
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-ic-webapp.yml --vault-password-file vault.key --private-key id_rsa -l ic_webapp
                                '''
                            }
                        }
                    }


                }
            }

        }
      }
    }  

    post {
        always {
            script {
                slackNotifier currentBuild.result
            }
        }
    }    
}
