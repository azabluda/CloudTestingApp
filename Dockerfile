# Stage 1: Build projects
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /source

# Copy csproj and restore as distinct layers
COPY src/*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*}/ && mv $file src/${file%.*}/; done
RUN dotnet restore src/CloudTestingApp.Api/CloudTestingApp.Api.csproj

# Copy everything else and build
COPY src/ ./src/
RUN dotnet publish src/CloudTestingApp.Blazor/CloudTestingApp.Blazor.csproj -c Release -o /app/blazor
RUN dotnet publish src/CloudTestingApp.Api/CloudTestingApp.Api.csproj -c Release -o /app/api

# Stage 2: Final image
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Copy build artifacts
COPY --from=build /app/api .
# Copy Blazor artifacts to Api's wwwroot
COPY --from=build /app/blazor/wwwroot ./wwwroot

# Rootless podman compatibility
USER $APP_UID

ENTRYPOINT ["dotnet", "CloudTestingApp.Api.dll"]
