terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.2.0"
    }
  }
}


provider "google" {
    credentials = "./keys_priv.json"
    #project     = "ads-project-401714"
    project = "adminsistemas-401916"
    region      = "europe-southwest1"
}