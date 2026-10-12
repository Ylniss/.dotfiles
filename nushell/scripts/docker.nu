alias dockercu = docker compose up
alias dockercub = docker compose up --build

def "docker stop all" [] {
  let ids = (docker ps --quiet | lines)
  if ($ids | is-not-empty) { docker stop ...$ids }
}

# Last arg is the compose project name, the rest go to 'docker ps'.
def "docker ps compose" --wrapped [...args] {
  let filter_arg = $'-f label=com.docker.compose.project=($args | last)'
  docker ps ...($args | drop) $filter_arg | from ssv
}

# -------------- PSQL -------------- 

# Start a postgres container (if needed) and store its connection env for 'docker psql'
def --env "docker psql start" [
  container_name: string,
  postgres_user: string,
  postgres_password: string,
  db_name: string
] {
  if (docker ps | from ssv | where NAMES == $container_name | is-empty) {
    docker run --name $container_name -e $'POSTGRES_USER=($postgres_user)' -e $'POSTGRES_PASSWORD=($postgres_password)' -e $'POSTGRES_DB=($db_name)' -d postgres
  }

  $env.DOCKER_PSQL_CONTAINER_NAME = $container_name
  $env.DOCKER_PSQL_POSTGRES_USER = $postgres_user
  $env.DOCKER_PSQL_DB_NAME = $db_name
}

# Execute `psql` commands inside the Docker container. Run 'docker psql start' first.
def "docker psql" [command: string] {
  docker exec -it $env.DOCKER_PSQL_CONTAINER_NAME psql -U $env.DOCKER_PSQL_POSTGRES_USER -d $env.DOCKER_PSQL_DB_NAME -c $command
}

