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

RUN dotnet test "./test/AspNetCoreInDocker.Web.Tests/AspNetCoreInDocker.Web.Tests.csproj" -c Release --no-build --no-restore

RUN dotnet publish "./src/AspNetCoreInDocker.Web/AspNetCoreInDocker.Web.csproj" -c Release -o "../../dist" --no-restore 

#App image
FROM microsoft/aspnetcore:2.0.3
WORKDIR /app
COPY --from=builder /sln/dist .
ENTRYPOINT ["dotnet", "AspNetCoreInDocker.Web.dll"]