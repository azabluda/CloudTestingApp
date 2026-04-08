# Stage 1: Build projects
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /source

# Copy csproj and restore as distinct layers
COPY src/*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*}/ && mv $file src/${file%.*}/; done
RUN dotnet restore src/CloudTestingApp.Api/CloudTestingApp.Api.csproj

# Copy everything else and build
COPY src/ ./src/
RUN dotnet publish src/CloudTestingApp.Api/CloudTestingApp.Api.csproj -c Release -o /app/publish

# Stage 2: Final image
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Copy build artifacts (SDK handles Blazor integration automatically)
COPY --from=build /app/publish .

# Run as non-root user
USER $APP_UID

ENTRYPOINT ["dotnet", "CloudTestingApp.Api.dll"]
