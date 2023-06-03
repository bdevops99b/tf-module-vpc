resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${var.env}-vpc" })
}

module "subnets" {
  source = "./subnets"
  for_each = var.subnets
  vpc_id = aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  name = each.value["name"]
  azs = each.value["azs"]
  tags = var.tags
  env = var.env
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.env}-igw" })
}

resource "aws_eip" "ngw" {
 # count = length(lookup(lookup(var.subnets, "public", null), "cidr_block", 0))  #this is also correct
  count = length(var.subnets["public"].cidr_block)
  vpc = true
  tags = merge(var.tags, { Name = "${var.env}-ngw" })
}
resource "aws_nat_gateway" "ngw" {
  count = length(var.subnets["public"].cidr_block)
  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = module.subnets["public"].subnet_ids[count.index]

  tags = merge(var.tags, { Name = "${var.env}-ngw" })
}

resource "aws_route" "igw" {
  count = length(module.subnets["public"].route_table_ids)
  route_table_id = module.subnets["public"].route_table_ids[count.index]
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ngw" {
  count = length(local.all_private_subnet_ids)
  route_table_id = local.all_private_subnet_ids[count.index]
  nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index )
  destination_cidr_block = "0.0.0.0/0"
}

output "ngw" {
  value = aws_nat_gateway.ngw
}

output "subnets" {
  value = module.subnets
}
