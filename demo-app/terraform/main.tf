module "ecr_repo" {
  source               = "git@github.com:leroykayanda/terraform-cloud-modules.git//aws/ecr_repo?ref=1.2.38"
  env                  = var.env
  service              = var.service
  image_tag_mutability = var.image_tag_mutability
  images_to_keep       = var.images_to_keep
}
