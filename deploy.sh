#! /bin/bash
echo "ENTER YOUR PROJECT ID:-"
read PROJECT_ID
gcloud config set project $PROJECT_ID 
gcloud services enable run.googleapis.com endpoints.googleapis.com \
cloudbuild.googleapis.com servicecontrol.googleapis.com servicemanagement.googleapis.com \

artifactregistry.googleapis.com  secretmanager.googleapis.com
cd service-1 
echo "ENTER YOUR RAPID API KEY "
read API_KEY_1
# First we need to create one service-account for each cloud run service and secret accessor iam role to respective secrets in secret manager

gcloud iam service-accounts create insta-api-run-service
gcloud iam service-accounts create omdb-api-run-service 
# Now we need to create secrets 
echo -n $API_KEY_1 |gcloud secrets create rapid-api-secret --replication-policy automatic \
--data-file -
gcloud secrets add-iam-policy-binding rapid-api-secret \
--member "serviceAcccount:insta-api-run-service@${PROJECT_ID}.iam.gserviceaccount.com" \
--role roles/secretmanager.secretAccessor

gcloud run deploy insta-profile-api --source . \
--ignore-file .gitignore \
--no-allow-unauthenticated \
--region us-central1 \ 
--service-account insta-api-run-service@${PROJECT_ID}.iam.gserviceaccount.com \
--update-secrets=API_KEY=rapid-api-secret:latest
cd ../service-2
echo "ENTER YOUR API KEY FOR OMDB API"
read API_KEY_2
echo -n $API_KEY_2 |gcloud secrets create omdb-api-secret --replication-policy automatic \
--data-file -
gcloud secrets add-iam-policy-binding omdb-api-secret \
--member "serviceAcccount:omdb-api-run-service@${PROJECT_ID}.iam.gserviceaccount.com" \
--role roles/secretmanager.secretAccessor
gcloud run deploy movies-api --source . \
--ignore-file .gitignore \
--no-allow-unauthenticated \
--region us-central1 \ 
--service-account nsta-api-run-service@${PROJECT_ID}.iam.gserviceaccount.com \
--update-secrets=API_KEY=omdb-api-secret:latest
cd ../
gcloud iam service-accounts create endpoints-run-sa 
gcloud run services add-iam-policy-binding insta-profile-api  --region us-central1 \
 --member "serviceAccount:endpoints-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role roles/run.invoker
gcloud run services add-iam-policy-binding  movies-api  --region us-central1 \
 --member "serviceAccount:endpoints-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role roles/run.invoker
gcloud run deploy api-gateway \
    --image="gcr.io/cloudrun/hello" \
    --allow-unauthenticated \
    --region us-central1
cd cloud-endpoints 
HOST=$(gcloud run services describe api-gateway --region us-central1 --format "value(status.address.url)")
MOVIES_API_URL=$(gcloud run services describe movies-api --region us-central1 --format "value(status.address.url)")
INSTA_PROFILE_API_URL=$(gcloud run services describe insta-profile-api --region us-central1 --format "value(status.address.url)")
MOD_HOST=$(echo "${HOST}" | sed 's/^https:\/\///')
sed -i 's/HOST/${MOD_HOST}/' openapi.yaml 
sed -i 's|MOVIES_API_URL|${MOVIES_API_URL}|' openapi.yaml 
sed -i 's|INSTA_PROFILE_API_URL|${INSTA_PROFILE_API_URL}|' openapi.yaml 
gcloud endpoints services  deploy openapi.yaml 
CONFIG_ID=$(gcloud endpoints configs list --service $MOD_HOST  --format json | jq '.[0].id')
./gcloud_build_image.sh -c $CONFIG_ID -s $ MOD_HOST -p $PROJECT_ID 
echo "ENTER THE URL OF IMAGE  YOU GOT IN OUTPUT "
read IMAGE_URL 
gcloud run deploy api-gateway --region us-central1 \
 --image $IMAGE_URL

 
