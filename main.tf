#Service account & Custome Role
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
#https://stackoverflow.com/questions/61003081/how-to-properly-create-gcp-service-account-with-roles-in-terraform
resource "google_service_account" "sa-demo1" {
  account_id    = "sa-demo1"
  display_name  = "Demo 1 Service Account"
}

#https://runebook.dev/es/docs/terraform/providers/google/r/google_project_iam
/* resource "google_project_iam_policy" "project" {
  project     = "rosalio-barrientos-epam-rd5"
  policy_data = "${data.google_iam_policy.demo-policy.policy_data}"
}
data "google_iam_policy" "demo-policy" {
  binding {
    role = "roles/pubsub.editor"
    members = ["serviceAccount:${google_service_account.sa-demo1.email}"]
  }
  binding {
    role = "roles/storage.objectAdmin"
    members = ["serviceAccount:${google_service_account.sa-demo1.email}"]
  }
  binding {
    role = "roles/storage.admin"
    members = ["serviceAccount:${google_service_account.sa-demo1.email}"]
  }
} */ #https://github.com/hashicorp/terraform-provider-google/issues/6854

#https://cloud.google.com/storage/docs/access-control/iam-roles
resource "google_project_iam_binding" "demo_pubsub" {
  project   = "rosalio-barrientos-epam-rd5"
  role      = "roles/pubsub.editor"
  members   = [ "serviceAccount:${google_service_account.sa-demo1.email}" ]
}
resource "google_project_iam_binding" "demo_storage_o_admin" {
  project   = "rosalio-barrientos-epam-rd5"
  role      = "roles/storage.objectAdmin"
  members   = [ "serviceAccount:${google_service_account.sa-demo1.email}" ]
}
resource "google_project_iam_binding" "demo_storage_admin" {
  project   = "rosalio-barrientos-epam-rd5"
  role      = "roles/storage.admin"
  members   = [ "serviceAccount:${google_service_account.sa-demo1.email}" ]
}

#Private Bucket for Cloud Storage
resource "google_storage_bucket" "bucket-rbarrientos1-demo" {
  name          = "bucket-rbarrientos1-demo"
  location      = "US"
  force_destroy = true 
  #(Optional, Default: false) When deleting a bucket, this boolean option will delete all contained objects. 
  #If you try to delete a bucket that contains objects, Terraform will fail that run.

  lifecycle_rule {
    condition {
      age = 5 #Minimum age of an object in days to satisfy this condition.
    }
    action {
      type = "Delete" #Passed age delete action will apply
    }
  }
}

#PubSub Topic & Subscription
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic
resource "google_pubsub_topic" "pubsub-topic-demo1" {
  name = "pubsub-topic-demo1"

  #labels = {
  #  foo = "demo1"
  #}
  message_retention_duration = "172800s" #2 days
  #Cannot be more than 7 days or less than 10 minutes.
}

#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
resource "google_pubsub_subscription" "subscription-demo1" {
  name  = "subscription-demo1"
  topic = google_pubsub_topic.pubsub-topic-demo1.name

  #labels = {
  #  foo = "bar"
  #}

  # 20 minutes
  message_retention_duration    = "1200s"
  retain_acked_messages         = true
  ack_deadline_seconds          = 20

  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }

  #enable_message_ordering    = false
}

#Cloud Scheduler
resource "google_cloud_scheduler_job" "demo1-job" {
  name          = "demo1-job"
  description   = "Job for "
  schedule      = "* * * * *"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name  = google_pubsub_topic.pubsub-topic-demo1.id
    data        = base64encode("test")
  }
  time_zone     = "America/Mexico_City"
}

#Compute Engine Creation (VM)
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#creating-a-vm-instance
resource "google_compute_instance" "demo1-instance" {
  name          = "demo1-instance"
  machine_type  = "e2-micro"
  zone          = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  } 
  network_interface {
    network = "default"

    #access_config {
    #  // Ephemeral IP
    #}
  }
  metadata_startup_script = file("script.sh")
  tags = ["terraform-compute-jobs"]
  
  service_account {
  email  = google_service_account.sa-demo1.email
  scopes = ["cloud-platform"]
  }
}
