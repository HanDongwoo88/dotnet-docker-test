# Build image
FROM microsoft/dotnet:2.0.3-sdk as builder
WORKDIR /sln

COPY ./aspnetcore-in-docker.sln ./NuGet.config  ./
COPY ./nuget/packages ./nuget/packages

# 더 빠른 빌드를 위해 모든 csproj 파일을 복사하고 복원하여 레이어를 캐시
# dotnet_build.sh 스크립트는 어쨌든 이것을 수행하므로 불필요하지만 도커는 중간 이미지를 캐시하여 더 빠르게 빌드 한다.
COPY ./src/AspNetCoreInDocker.Lib/AspNetCoreInDocker.Lib.csproj  ./src/AspNetCoreInDocker.Lib/AspNetCoreInDocker.Lib.csproj
COPY ./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj  ./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj
COPY ./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj  ./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj
RUN dotnet restore

COPY ./test ./test
COPY ./src ./src
RUN dotnet build -c Release --no-restore

#RUN dotnet test "./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj" --results-directory "../../test_results" --logger "trx;LogFileName=result.xml"

RUN dotnet publish "./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj" -c Release -o "../../dist" --no-restore 
#commit test
#App image
FROM microsoft/aspnetcore:2.0.3
WORKDIR /app
COPY --from=builder /sln/dist .

ENTRYPOINT ["dotnet", "AspNetCoreInDocker.Web.dll"]