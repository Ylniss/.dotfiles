alias dockercu = docker compose up
alias dockercub = docker compose up --build

# Stops all running containers
def "docker stop all" [] {
  docker ps | from ssv | get NAMES | each { |it| docker stop $it }
}

# List all containers within a compose
def "docker psc" --wrapped [...args] {
  if ($args | length) == 1 {
    let project_name = $args.0
    let filter_arg = $'-f label=com.docker.compose.project=($project_name)'
    docker ps $filter_arg | from ssv
  } else {
    let project_name = $args | last
    let options = $args | drop
    let filter_arg = $'-f label=com.docker.compose.project=($project_name)'
    docker ps ...$options $filter_arg | from ssv
  }
}

# -------------- PSQL --------------

# Run docker contiainer with postgres and set environment variables for psql session
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

  $env.docker_psql_container_name = $container_name
  $env.docker_psql_postgres_user = $postgres_user
  $env.docker_psql_db_name = $db_name
}

# Execute `psql` commands inside the Docker container
def "docker psql" [command: string] {
  try {
    docker exec -it $env.docker_psql_container_name psql -U $env.docker_psql_postgres_user -d $env.docker_psql_db_name -c $"($command)"
  } catch {
    "Set the Docker PostgreSQL environment variables first using 'docker psqls'."
  }
}
