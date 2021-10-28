pipeline {
    agent { label 'master'}
	parameters {
        string(name: 'AWS_REGION', defaultValue: 'eu-central-1', description: 'aws region for ansible aws modules')
		
		string(name: 'VPC_NAME', defaultValue: 'deploy-vpc', description: 'existing vpc tag-name')

		string(name: 'ECR_URL',
			defaultValue: '232484871880.dkr.ecr.eu-central-1.amazonaws.com',
			description: 'ecr url without repo name')

		string(name: 'ECS_CLUSTER_NAME',
			defaultValue: 'petclinic-CI-QA-deploy',
			description: 'ecs cluster name')
    }
    stages {
        stage('Dependencies') {
            steps {
                sh 'ansible-galaxy collection install -r ansible/requirements.yml'
            }
        }
		stage ('ansible-playbook') {
			steps {
				withCredentials([[
					$class: 'AmazonWebServicesCredentialsBinding',
					credentialsId: "aws-admin",
					accessKeyVariable: 'AWS_ACCESS_KEY_ID',
					secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
				]]) {
					ansiblePlaybook(inventory: 'ansible/hosts.ini', playbook: 'ansible/deploy-service-ci.yml')
				}
			}
		}
	}
}
