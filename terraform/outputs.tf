output "vpc_id" { value = module.vpc.vpc_id }
output "eks_cluster_name" { value = module.eks.cluster_name }
output "eks_cluster_endpoint" { value = module.eks.cluster_endpoint }
output "alb_controller_role_arn" { value = module.eks.alb_controller_role_arn }
output "backend_ecr_url" { value = module.ecr.backend_repo_url }
output "frontend_ecr_url" { value = module.ecr.frontend_repo_url }
