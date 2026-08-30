provider "aws" {
  region  = var.region
  profile = "asiayo"

  default_tags {
    tags = {
      Project = "AsiaYo"
    }
  }
}
