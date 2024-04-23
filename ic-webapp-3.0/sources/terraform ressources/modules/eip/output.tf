output "output_eip" {
  value = aws_eip.my_eip.public_ip
}

output "output_eip_id" {
  value = aws_eip.my_eip.id
}