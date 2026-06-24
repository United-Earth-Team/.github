#! /bin/bash

# Function to display the script's usage
display_help() {
    echo "Usage: $0 [CONTAINER_NAME] [DOCKER_COMPOSE_FILE]"
    echo
    echo "Positional arguments:"
    echo "  CONTAINER_NAME       Name of the docker container for script to check the status. (Required)"
    echo "  DOCKER_COMPOSE_FILE  Name of the Compose YAML file. Default is 'compose.yaml'."
    echo
    echo "Optional arguments:"
    echo "  -h, --help           Display this help message."
    exit 1
}

# Check for the help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
fi

# Check if CONTAINER_NAME is provided
if [[ -z "$1" ]]; then
    echo "error: CONTAINER_NAME is a required argument."
    display_help
    exit 1
fi

# relative path of shell file to the dir where user execuete the shell file
RELATIVE_SHELL_DIR=$(dirname "$BASH_SOURCE")
CONTAINER_NAME=$1
DOCKER_COMPOSE_FILE=${RELATIVE_SHELL_DIR}/${2:-"compose.yaml"}

# start docker
MAX_CHECK_TIMES=10

echo "deploying $CONTAINER_NAME..."
sudo docker compose -f $DOCKER_COMPOSE_FILE -p $CONTAINER_NAME down --rmi all
sudo docker compose -p $CONTAINER_NAME -f $DOCKER_COMPOSE_FILE up -d

sleep 5

check_times=0
echo "checking status of container $CONTAINER_NAME..."
while  [ $check_times -lt $MAX_CHECK_TIMES ]; do
    if [ "$(sudo docker ps -q -f name=$CONTAINER_NAME)" ]; then

        container_status=$(sudo docker inspect --format '{{.State.Status}}' $CONTAINER_NAME 2>/dev/null)
        if [[ "$container_status" == "running" ]]; then
            echo "successfully started container $CONTAINER_NAME!"
            exit 0
        fi

    fi
    ((check_times++))
    sleep 2
done
echo "failed started compose $CONTAINER_NAME!"
exit 1
