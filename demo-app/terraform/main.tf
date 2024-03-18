module "ecr_repo" {
  source               = "app.terraform.io/RentRahisi/modules/cloud//aws/aws-ecr-repo"
  version              = "1.0.7"
  env                  = var.env
  microservice_name    = var.service
  image_tag_mutability = var.image_tag_mutability
}
