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
		} finally {
            sh "pwd"
            sh "ls"
            sh "cat test/AspNetCoreInDocker.Web.Tests/test_results/result.xml"
            step ([$class: 'MSTestPublisher', testResultsFile:"**/test_results/result.xml", failOnError: true, keepLongStdio: true])
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