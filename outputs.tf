output "sns_topic_arn" {
  value = aws_sns_topic.cost_anomaly_topic.arn
}

output "monitor_by_service_arn" {
  value = aws_ce_anomaly_monitor.by_service.arn
}

output "monitor_by_tag_arn" {
  value       = try(aws_ce_anomaly_monitor.by_tag[0].arn, null)
  description = "ARN del monitor por tag (si fue creado)"
}
