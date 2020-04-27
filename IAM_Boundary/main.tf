provider "aws" {
  profile = var.profile
  region  = var.region
}


module "instance_profile_build" {
  source = "./MOD_BOUNDARY"
}
