#!/usr/bin/env bash
set -euo pipefail

action="${1:-up}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
infra_dir="$(cd "${script_dir}/.." && pwd)"
jenkins_dir="${infra_dir}/jenkins"
env_file="${infra_dir}/.env"
env_template="${infra_dir}/.env.example"
data_dir="${infra_dir}/jenkins_data"
default_kubeconfig_file="${infra_dir}/kubeconfig"

if [[ ! -f "${env_file}" ]]; then
  cp "${env_template}" "${env_file}"
  echo "Created infra/.env from template. Update values before running pipelines."
fi

mkdir -p "${data_dir}"
touch "${default_kubeconfig_file}"

if ! docker info >/dev/null 2>&1; then
  echo "Docker Engine is not reachable."
  echo "Start Docker Desktop (or Docker daemon) and run this script again."
  echo "Quick check: docker version"
  exit 1
fi

cd "${jenkins_dir}"

case "${action}" in
  up)
    docker compose --env-file ../.env up -d --build
    ;;
  down)
    docker compose --env-file ../.env down
    ;;
  logs)
    docker compose --env-file ../.env logs -f --tail=200
    ;;
  rebuild)
    docker compose --env-file ../.env build --no-cache
    ;;
  reset)
    docker compose --env-file ../.env down -v --remove-orphans
    ;;
  *)
    echo "Usage: ./infra/scripts/jenkins.sh [up|down|logs|rebuild|reset]"
    exit 1
    ;;
esac
