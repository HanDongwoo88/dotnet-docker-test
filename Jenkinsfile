def label = "jenkins-slave-${UUID.randomUUID().toString()}"

podTemplate(
	label: label, 
	containers: [
		//container Template 설정
		containerTemplate(name: "docker", image: "docker:rc", ttyEnabled: true, command: "cat"),
		containerTemplate(name: "kubectl", image: "lachlanevenson/k8s-kubectl", command: "cat", ttyEnabled: true),
        containerTemplate(name: "dotnet", image: "microsoft/dotnet:2.0.3-sdk", command: "cat", ttyEnabled: true),
        containerTemplate(name: "helm", image: "lwolf/helm-kubectl-docker", ttyEnabled: true, command: "cat")
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
			stage( "Deploy to Cluster" ) {
				container("helm") {
                    sh "helm init"	//tiller 설치

                    // helm repo add
					echo "Add helm repo"
                    sh "helm version"
                    sh "helm repo add ${baseDeployDir} ${helmRepositoryURL}"
                    sh "helm repo update"
                    
                    /*
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
						 sh "helm install ${releaseName} ${helmChartfile} --namespace ${namespace}"	
                         //sh "helm install ${helmChartfile} --name ${releaseName}" (Helm v2)				
					}
                    */
                    sh "helm ls -q --namespace default"
                    try {
                        sh "helm delete ${releaseName}"	
					} catch(e) {
						echo "Clear-up Error : " + e.getMessage()
						echo "Continue process"	
					}

                    echo "Install with chart file !"
					sh "helm install ${releaseName} ${helmChartfile} --namespace ${namespace}"	
				}
			}
		} catch(e) {
			currentBuild.result = "FAILED"
		} 
	}
}