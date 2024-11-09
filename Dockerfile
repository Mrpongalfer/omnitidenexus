# Default Dockerfile
FROM mcr.microsoft.com/powershell:lts-alpine-3.13
WORKDIR /app
COPY . /app
ENTRYPOINT ["pwsh", "-NoExit"]
