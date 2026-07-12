alias dockercu = docker compose up
alias dockercub = docker compose up --build

def "docker stop all" [] {
  let names = (docker ps | from ssv | get NAMES)
  if ($names | is-not-empty) { docker stop ...$names }
}

# List all containers within a compose
def "docker psc" --wrapped [...args] {
  let filter_arg = $'-f label=com.docker.compose.project=($args | last)'
  docker ps ...($args | drop) $filter_arg | from ssv
}

# -------------- PSQL -------------- 

# Start a postgres container (if needed) and store its connection env for 'docker psql'
def "docker psqls" --env [
  container_name: string,
  postgres_user: string,
  postgres_password: string,
  db_name: string
] {
  let container_running = (docker ps | from ssv | where NAMES == $container_name | length) > 0
  if not $container_running {
    docker run --name $container_name -e $'POSTGRES_USER=($postgres_user)' -e $'POSTGRES_PASSWORD=($postgres_password)' -e $'POSTGRES_DB=($db_name)' -d postgres
  }

  $env.DOCKER_PSQL_CONTAINER_NAME = $container_name
  $env.DOCKER_PSQL_POSTGRES_USER = $postgres_user
  $env.DOCKER_PSQL_DB_NAME = $db_name
}

# Execute `psql` commands inside the Docker container
def "docker psql" [command: string] {
  try {
    docker exec -it $env.DOCKER_PSQL_CONTAINER_NAME psql -U $env.DOCKER_PSQL_POSTGRES_USER -d $env.DOCKER_PSQL_DB_NAME -c $"($command)"
  } catch {
    "Set the Docker PostgreSQL environment variables first using 'docker psqls'."
  }
}

