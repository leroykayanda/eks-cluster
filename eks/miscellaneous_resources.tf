# Keycloak DB SG

resource "aws_security_group" "keycloak_db_sg" {
  name        = "${var.env}-keycloak-DB-SG"
  description = "${var.env}-keycloak-DB-SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = var.keycloak_aurora_settings[var.env]["port"]
    to_port     = var.keycloak_aurora_settings[var.env]["port"]
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "DB Port"
  }

  tags = {
    Name = "${var.env}-keycloak-DB-SG"
  }
}

# R53 hosted zone

resource "aws_route53_zone" "zone" {
  name = var.base_domain_name
}

# ACM cert

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.base_domain_name}"
  validation_method = "DNS"
}
