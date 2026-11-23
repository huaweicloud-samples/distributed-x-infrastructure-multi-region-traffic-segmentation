# --- infra/modules/vpc/outputs.tf ---

output "vpc_id" {
  value = huaweicloud_vpc.this.id
}

output "vpc_cidr" {
  value = huaweicloud_vpc.this.cidr
}

output "subnet_ids" {
  value = huaweicloud_vpc_subnet.this[*].id
}

output "er_attachment_id" {
  value = huaweicloud_er_vpc_attachment.this.id
}

output "segment" {
  value = var.segment
}
