@ECHO OFF
REM Make batch file to build Nautobot container
REM Author: Benjamin P. Trachtenberg
REM Version: 2025.3.14.001
REM

SET option=%1
SET container_version=%2

IF "%option%" == "" (
    GOTO BAD_OPTIONS
)

IF "%container_version%" == "" (
    GOTO BAD_OPTIONS
)

IF "%option%" == "build-podman-nautobot" (
    @ECHO "Building the nautobot container with container_version=%container_version% in podman"
    podman build --tag nauotbot-ntc-custom:latest --tag nauotbot-ntc-custom:%container_version% -f Containerfile --format docker
    GOTO END

IF "%option%" == "build-docker-nautobot" (
    @ECHO "Building the nautobot container with container_version=%container_version% in docker"
    docker build --tag nauotbot-ntc-custom:latest --tag nauotbot-ntc-custom:%container_version% -f Containerfile
    GOTO END

@ECHO make options
@ECHO     build-podman-nautobot             To build the container in podman
@ECHO     build-docker-nautobot             To build the container in docker
GOTO END

:BAD_OPTIONS
@ECHO Argument is missing
@ECHO Usage: make.bat option container_version
@ECHO.
GOTO END

:END
