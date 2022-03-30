# DEMO1

RD GCP 5 - Demo
This project is intended to create GCP Insfraestructure in automated way using Jenkins and Terraform.
Terraform scripts were created, the GCP resources configured and integrated in a pipeline as described below:

Create a service account (SA) with a custom role that has the minimum roles/permissions to 
read from PubSub and write into GCS (Cloud Storage). 
a. Create a Compute Engine instance setting up the SA created before.
b. Create a PubSub Topic and Subscription.
c. Create a Cron job which uses gcloud command to read the PubSub messages and write it into GCS as a json file
d. Create a Cloud Scheduler to publish a new message to the PubSub topic every 1 minute at Mexico City time zone (CST). 

Once this was configured via Terraform, Jenkins will run this in automated way running above commands/stages.
- Terraform Init
- Terraform Plan
- Terraform Apply
- Terraform Destroy