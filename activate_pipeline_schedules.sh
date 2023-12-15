#!/usr/bin/env bash
IFS=$' \t\r\n'
set -e

function log_info() {
  >&2 echo -e "[\\e[1;94mINFO\\e[0m] $*"
}

function get_pipeline_schedules() {
    local project_id=$1

    curl -s -X GET \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipeline_schedules" \
        -H "Authorization: Bearer ${PRIVATE_TOKEN}"
}


# Vérifier si le token d'accès est défini
if [ -z "${PRIVATE_TOKEN}" ]; then
    read -rp "Enter you GitLab personal token (PRIVATE_TOKEN): " PRIVATE_TOKEN
fi
# Vérifier si le token d'accès est défini
if [ -z "${GROUP_NAME}" ]; then
    read -rp "Enter your gitlab GROUP name: " GROUP_NAME
fi
# Vérifier si le token d'accès est défini
if [ -z "${GITLAB_URL}" ]; then
    read -rp "Enter your gitlab URL: " GITLAB_URL
fi

GROUP_ID=$(curl -sSf -H  "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/groups?search=$GROUP_NAME" | jq -r '.[0].id')
log_info "...\\e[33;1mGROUP_ID:${GROUP_ID}\\e[0m"
 
# check if the group exist
if [ -n "$GROUP_ID" ]; then
    # Récupération des projets du groupe
    PROJECTS=$(curl -sSf -H "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/groups/${GROUP_ID}/projects" | jq -r '.[] | .id') 

    log_info "...\\e[33;1mPROJECTS:${PROJECTS}\\e[0m"

    # Pour chaque projet, récupérer les pipeline_schedules et les activer
    for PROJECT_ID in $PROJECTS; do
        # Récupération des pipeline_schedules du projet
        PIPELINE_SCHEDULES=$(curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/projects/$PROJECT_ID/pipeline_schedules" | jq -r '.[].id')
        # Edition et activation des pipeline_schedules
        for SCHEDULE_ID in $PIPELINE_SCHEDULES; do
            # Edition du pipeline_schedule pour le mettre en "Activated"
            curl --request PUT --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/projects/$PROJECT_ID/pipeline_schedules/$SCHEDULE_ID" \
                --data "active=true"

            log_info "...\\e[33;1m The pipeline_schedule ID:${SCHEDULE_ID} of project ID:${PROJECT_ID} has been edited and activated.\\e[0m"
        done
    done

    log_info "...\\e[33;1mAll pipeline_schedules of projects in group '$GROUP_NAME' have been edited and activated \\e[0m"
else
    log_info "...\\e[33;1mThe gitlab group '$GROUP_NAME' was not found\\e[0m"
fi
