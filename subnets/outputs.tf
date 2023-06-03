output "subnet_ids" {
  value = aws_subnet.main.*.id
}

output "route_table_ids" {
  value = aws_route_table.main.*.id
}