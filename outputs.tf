output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "webserver_private_ip" {
  value = ws_instance.server.prvate_ip
}

output "webserver_public_ip" {
  value = aws_instance.server.public_ip
}

