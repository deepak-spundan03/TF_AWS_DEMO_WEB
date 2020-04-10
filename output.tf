output "vpc_id" {
  value = aws_vpc.web.id
}

output "public_subnet_id" {
  value = aws_subnet.public-subnet.id
}
output "private_subnet_id" {
  value = aws_subnet.private-subnet.id
}

output "igw_id" {
  value = aws_internet_gateway.internet-gw.id
}

output "eip_id" {
  value = aws_eip.nat.id
}


output "nat_gateway_id" {
  value = aws_nat_gateway.nat-gw.id
}

output "public_route_table_id" {
  value = aws_route_table.web-public-rt.id
}

output "private_route_table_id" {
  value = aws_route_table.web-private-rt.id
}


output "security_group" {
  value = aws_security_group.web-security-group.*.id
}









