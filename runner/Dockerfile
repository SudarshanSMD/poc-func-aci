FROM mcr.microsoft.com/powershell:latest


COPY . /app

WORKDIR /app


#install curl
RUN apt-get update && apt-get install -y curl

RUN useradd -m dangerousdave


#CMD ["pwsh", "-File", "script.ps1"]

# set the user to "docker" so all subsequent commands are run as the docker user
USER dangerousdave


RUN pwsh -Command "Write-Host 'Hello from Docker! This is an inline PowerShell script.'"


#Run Script
CMD ["pwsh", "-File", "test.ps1"]
