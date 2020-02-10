def label = "jenkins-slave-${UUID.randomUUID().toString()}"

podTemplate(
	label: label, 
	containers: [
		//container Template 설정
		containerTemplate(name: "docker", image: "docker:rc", ttyEnabled: true, command: "cat"),
		containerTemplate(name: "kubectl", image: "lachlanevenson/k8s-kubectl", command: "cat", ttyEnabled: true),
        containerTemplate(name: "dotnet", image: "microsoft/dotnet:2.0.3-sdk", command: "cat", ttyEnabled: true),
        containerTemplate(name: "helm", image: "dtzar/helm-kubectl:2.16.1", ttyEnabled: true, command: "cat")
	],
	//volume mount
	volumes: [
		hostPathVolume(hostPath: "/var/run/docker.sock", mountPath: "/var/run/docker.sock")
	]
) 
{
	node(label) {
		stage("Get Source") {
			git "https://github.com/HanDongwoo88/dotnet-docker-test.git"

		}
        try {
            stage('Unit Test') {
                container("dotnet") {
                    sh "dotnet test './test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj' --results-directory './test_results' --logger 'trx;LogFileName=result.xml'"
                    
                }
            }
        } catch(e) {
			currentBuild.result = "TEST FAILED"
		}

		//-- 환경변수 파일 읽어서 변수값 셋팅
		def props = readProperties  file:"pipeline.properties"
		def tag = props["version"]
		def dockerRegistry = props["dockerRegistry"]
		def credential_registry=props["credential_registry"]
		def image = props["image"]
		def baseDeployDir = props["baseDeployDir"]
		def helmRepository = props["helmRepository"]
		def helmChartname = props["helmChartname"]
		def helmChartfile = "${baseDeployDir}/${helmChartname}"
		def releaseName = props["releaseName"]
		def namespace = props["namespace"]
        def helmRepositoryURL = props["helmRepositoryURL"]
        def helmChartVersion =  props["helmChartVersion"]

		//def deployment = props["deployment"]
		//def service = props["service"]
		//def ingress = props["ingress"]
		//def selector_key = props["selector_key"]
		//def selector_val = props["selector_val"]

		try {
			stage("Build Microservice image") {
				container("docker") {
					docker.withRegistry("${dockerRegistry}", "${credential_registry}") {
						sh "docker build -f ./Dockerfile -t ${image}:${tag} ."
						sh "docker push ${image}:${tag}"
						sh "docker tag ${image}:${tag} ${image}:latest"
						sh "docker push ${image}:latest"
					}
				}
			}
            //--- 무중단 배포를 위해 clean up 하지 않음
			/*
			stage( "Clean Up Existing Deployments" ) {
				container("helm") {
					try {
                        sh "helm delete ${releaseName}"	
					} catch(e) {
						echo "Clear-up Error : " + e.getMessage()
						echo "Continue process"	
					}
				}
			}
            */
            stage("Update Helm Chart") {
                container("helm") {

                    git "https://github.com/HanDongwoo88/helm-charts.git"
                    
                    sh "helm init --client-only"
                    sh "pwd"
                    sh "ls"
                    sh "helm package dotnet-helm"
                    sh "ls"
                    //sh "cp dotnet-helm-${helmChartVersion}.tgz /"
                    
                    sh "helm repo index ."
                    sh "ls"
                    sh "helm serve --repo-path . &"
                    sh "helm repo add localrepo http://127.0.0.1:8879/charts"
                    sh "helm repo index ."



                    sh "helm repo update"
                    
                    sh "helm repo list"


                    sh "helm search dotnet"

                    /*

                    withCredentials([usernamePassword(credentialsId: 'ci-github', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                        sh('git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/my-org/my-repo.git')
                    }
                    */

                    /*
                    sshagent(credentials: ["406ef572-9598-45ee-8d39-9c9a227a9227"]) {
                        def repository = "git@" + env.GIT_URL.replaceFirst(".+://", "").replaceFirst("/", ":")
                        sh("git remote set-url origin $repository")
                        sh("git tag --force build-${env.BRANCH_NAME}")
                        sh("git push --force origin build-${env.BRANCH_NAME}")
                    }
                    */
                }
            }

			stage( "Deploy to Cluster" ) {
				container("helm") {
                    sh "helm init"	//tiller 설치

                    // version 확인
                    echo "Confirm Helm Version"
                    sh "helm version"
                    // helm repo add
					//echo "Add helm repo"
                    //sh "helm repo add ${baseDeployDir} ${helmRepositoryURL}"
                    sh "helm repo update"
                    
                    sh "helm repo list"

                    sh "helm search dotnet"
                    
                    boolean isExist = false
					
					//====== 이미 설치된 chart 인지 검사 =============
					String out = sh script: "helm ls -q --namespace ${namespace}", returnStdout: true
					if(out.contains("${releaseName}")) isExist = true
					//===========================				
					
					if (isExist) {
						echo "Already installed. I will upgrade it with chart file."
                        sh "helm ls -q --namespace default"	
						sh "helm upgrade ${releaseName} ${helmChartfile}"					
					} else {
						echo "Install with chart file !"
                        sh "helm install ${helmChartfile} --name ${releaseName} --namespace ${namespace}"
						//sh "helm install ${releaseName} ${helmChartfile} --namespace ${namespace}" (Helm v3)
                        //sh "helm install ${helmChartfile} --name ${releaseName}" (Helm v2)				
					}
				}
			}
		} catch(e) {
			currentBuild.result = "FAILED"
		} 
	}
}