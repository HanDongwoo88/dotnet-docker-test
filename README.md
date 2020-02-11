# ASP.NET Core in Kubernetes    
ASP.NET CORE Docker test


## list  
/nuget - .netcore application에서 가져오는 nuget package파일  
/src - .netcore application 소스  
/test - .netcore application unittest file(xunit)  
      
Dockerfile - 배포 image build 정의 파일  
deploy.yaml - pod 배포 정의 파일  
svc.yaml - service 정의 파일  
jenkinsfile - jenkins pipeline 정의 파일  
pipeline.properties - jenkinsfile에서 참조하는 환경변수 정의 파일    
NuGet.config - .netcore application의 nuget package 경로 설정파일  
docker-compose.yml - docker compose용 docker container 정의 파일 (현재 사용하지 않음)  
docker-compose.override.yml - docker compose용 docker container 정의 파일 (현재 사용하지 않음)  
