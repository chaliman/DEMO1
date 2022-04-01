#Service account & Custome Role
resource "google_service_account" "sa-demo1" {
  account_id    = "sa-demo1"
  display_name  = "Demo 1 Service Account"
}

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
} 

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
resource "google_pubsub_topic" "pubsub-topic-demo1" {
  name = "pubsub-topic-demo1"

  message_retention_duration = "172800s" #2 days
  #Cannot be more than 7 days or less than 10 minutes.
}

resource "google_pubsub_subscription" "subscription-demo1" {
  name  = "subscription-demo1"
  topic = google_pubsub_topic.pubsub-topic-demo1.name

  message_retention_duration    = "1200s"
  retain_acked_messages         = true
  ack_deadline_seconds          = 20

  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }

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

  }
  metadata_startup_script = file("script.sh")
  tags = ["terraform-compute-jobs"]
  
  service_account {
  email  = google_service_account.sa-demo1.email
  scopes = ["cloud-platform"]
  }
}
