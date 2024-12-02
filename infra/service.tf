locals {
  api_container_name = "api"
  api_container_port = 8080
  cpu = 256
  memory = 512
  api_tags = {
    service    = "api"
    cluster    = local.name
    terraform  = true
  }
  secrets = [
    for param in data.aws_ssm_parameters_by_path.api.arns : 
    {
      "name"      = substr(param, 53, -1),
      "valueFrom" = param
    } 
  ]
}

#
data "aws_ssm_parameters_by_path" "api" {
  path = "/prd/api/"
  recursive = true
  with_decryption = false
}
data "aws_ecr_image" "api_ecr_tag" {
  repository_name = "api"
  most_recent     = true
}
data "aws_ecr_repository" "api_ecr_repository" {
  name = data.aws_ecr_image.api_ecr_tag.repository_name
}

module "api_ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"
  version = "v5.7.0"
  # Service
  name                     = local.api_container_name
  cluster_arn              = module.ecs_cluster.cluster_arn
  enable_execute_command   = true
  cpu                      = local.cpu
  memory                   = local.memory
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1
  network_mode = "bridge"
  launch_type = "EC2"
  # Task Definitioncame
  requires_compatibilities = ["EC2"]

  capacity_provider_strategy = {
    as-1 = {
      capacity_provider = module.ecs_cluster.autoscaling_capacity_providers["as-1"].name
      weight            = 1
      base              = 1
    }
  }
  # Container definition(s)
  container_definitions = {
    (local.api_container_name) = {
      image  = "${data.aws_ecr_repository.api_ecr_repository.repository_url}:${data.aws_ecr_image.api_ecr_tag.image_tags[0]}"
      cpu    = local.cpu
      memory = local.memory
      port_mappings = [
        {
          name          = local.api_container_name
          containerPort = local.api_container_port
          protocol = "tcp"
        }
      ]
      readonly_root_filesystem = false
      secrets                  = local.secrets
      enable_cloudwatch_logging = true
    }
  }

  placement_constraints = [
    {
      type = "distinctInstance"
    }
  ]
  load_balancer = {
    service = {
      target_group_arn = element(module.api_alb.target_group_arns, 0)
      container_name   = local.api_container_name
      container_port   = local.api_container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = local.api_container_port
      to_port                  = local.api_container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.autoscaling_sg.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = local.api_tags
}

module "api_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"
  preserve_host_header = true
  name = local.api_container_name
  xff_header_processing_mode = "preserve"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.autoscaling_sg.security_group_id]

#   https_listeners = [
#     {
#       port               = 443
#       protocol           = "HTTPS"
#       target_group_index = 0
#     }
#   ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
  target_groups = [
    {
      name                 = "${local.api_container_name}"
      backend_protocol     = "HTTP"
      backend_port         = local.api_container_port
      target_type          = "instance"
      deregistration_delay = 5
      health_check = {
        enabled  = true
        path     = "/metadata"
        port     = "traffic-port"
        protocol = "HTTP"
        matcher  = "200"
      }
    },
  ]
}

output "URL" {
  value = module.api_alb.lb_dns_name
}