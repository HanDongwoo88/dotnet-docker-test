# Build image
FROM microsoft/dotnet:2.0.3-sdk AS builder
WORKDIR /sln

COPY ./aspnetcore-in-docker.sln ./NuGet.config  ./
COPY ./nuget/packages ./nuget/packages

# �� ���� ���带 ���� ��� csproj ������ �����ϰ� �����Ͽ� ���̾ ĳ��
# dotnet_build.sh ��ũ��Ʈ�� ��·�� �̰��� �����ϹǷ� ���ʿ������� ��Ŀ�� �߰� �̹����� ĳ���Ͽ� �� ������ ���� �Ѵ�.
COPY ./src/AspNetCoreInDocker.Lib/AspNetCoreInDocker.Lib.csproj  ./src/AspNetCoreInDocker.Lib/AspNetCoreInDocker.Lib.csproj
COPY ./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj  ./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj
COPY ./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj  ./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj
RUN dotnet restore

COPY ./test ./test
COPY ./src ./src
RUN dotnet build -c Release --no-restore

RUN dotnet test "./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj" --results-directory "../../testresults" --logger "trx;LogFileName=test_results.xml"

WORKDIR /sln
COPY ./ ./testresults 

RUN dotnet publish "./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj" -c Release -o "../../dist" --no-restore 
#commit test
#App image
FROM microsoft/aspnetcore:2.0.3
WORKDIR /app
COPY --from=builder /sln/dist .
COPY --from=builder /sln/testresults/test_results.xml jenkinsindocker:/var/jenkins_home/workspace/docker-test

ENTRYPOINT ["dotnet", "AspNetCoreInDocker.Web.dll"]