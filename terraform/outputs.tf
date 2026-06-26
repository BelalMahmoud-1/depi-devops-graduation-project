output "backend_ecr_url" { value = module.ecr.backend_repo_url }
output "frontend_ecr_url" { value = module.ecr.frontend_repo_url }
output "eks_cluster_name" { value = module.eks.cluster_name }
output "eks_cluster_endpoint" { value = module.eks.cluster_endpoint }
