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
        //-- 환경변수 파일 읽어서 변수값 셋팅
		def props = readProperties  file:"pipeline.properties"
        def applicationRepositoryURL = props["applicationRepositoryURL"]
        def helmChartTemplateURL = props["helmChartTemplateURL"]
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

		stage("Get Source") {
			git "${applicationRepositoryURL}"
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
                    git "${helmChartTemplateURL}"
                    
                    echo "Helm Init"
                    sh "helm init --client-only"

                    echo "Helm packing > make tgz file"
                    sh "helm package dotnet-helm"
                    
                    echo "Make Helm index.yaml file"
                    sh "helm repo index ."
                    
                    echo "Start Local Helm Repository"
                    sh "helm serve --repo-path . &"

                    echo "Add Helm Repository"
                    sh "helm repo add localrepo ${helmRepositoryURL}"
                    sh "helm repo index ."

                    echo "Update Helm Repository"
                    sh "helm repo update"
                    
                    echo "confirm helm repository list"
                    sh "helm repo list"
                    sh "helm search dotnet"
                }
            }
			stage( "Deploy to Cluster" ) {
				container("helm") {
                    // version 확인
                    echo "Confirm Helm Version"
                    sh "helm version"
                    
                    boolean isExist = false
					
					//====== 이미 설치된 helm chart 인지 검사 =============
					String out = sh script: "helm ls -q --namespace ${namespace}", returnStdout: true
					if(out.contains("${releaseName}")) isExist = true
					//===========================				
					
                    // 설치되지 않은 경우, helm install
                    // 설치된 경우, helm upgrade 
					if (isExist) {
						echo "Already installed. I will upgrade it with chart file."
                        sh "helm ls -q --namespace default"	
						sh "helm upgrade ${releaseName} ${helmChartfile}"					
					} else {
						echo "Install with chart file !"
                        sh "helm install ${helmChartfile} --name ${releaseName} --namespace ${namespace}"

                        // helm version 3부터는 install flag가 변경.. --namespace flag를 더이상 사용하지 않음
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