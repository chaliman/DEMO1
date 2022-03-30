terraform {
  backend "gcs" {
    bucket = "bucket-rbarrientos-demo"
    prefix = "terraform/demo1"
    #credentials = "/home/rbarrientos/rosalio-barrientos-epam-rd5-8b618f1ae936.json"
  }
}