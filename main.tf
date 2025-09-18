# ========== SNS para notificaciones ==========
resource "aws_sns_topic" "cost_anomaly_topic" {
  name = var.sns_topic_name
}

# (Opcional) Suscripción por email
resource "aws_sns_topic_subscription" "email_sub" {
  count     = var.alert_to_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.cost_anomaly_topic.arn
  protocol  = "email"
  endpoint  = var.alert_to_email
}

# ========== Monitor 1: por Servicio ==========
resource "aws_ce_anomaly_monitor" "by_service" {
  name              = "anomaly-by-service"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

# ========== Monitor 2: por TAG (opcional) ==========
# Formato para TAG en CE: "TAG_KEY$TAG_VALUE"
resource "aws_ce_anomaly_monitor" "by_tag" {
  count        = var.enable_tag_monitor ? 1 : 0
  name         = "anomaly-by-tag-${var.tag_key}-${var.tag_value}"
  monitor_type = "CUSTOM"

  monitor_specification = jsonencode({
    Dimensions = {
      Key    = "TAG"
      Values = ["${var.tag_key}$${var.tag_value}"]
    }
  })
}

# ========== Suscripción (alertas) ==========
resource "aws_ce_anomaly_subscription" "sub" {
  name      = "cost-anomaly-subscription"
  frequency = var.frequency # DAILY | WEEKLY | IMMEDIATE

  # Incluye el monitor por servicio y, si está activo, el de TAG
  monitor_arn_list = concat(
    [aws_ce_anomaly_monitor.by_service.arn],
    var.enable_tag_monitor ? [aws_ce_anomaly_monitor.by_tag[0].arn] : []
  )

  # Umbral ABSOLUTO en USD (para porcentaje usa ANOMALY_TOTAL_IMPACT_PERCENTAGE)
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [tostring(var.threshold_usd)] # ej: "50"
    }
  }

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly_topic.arn
  }
}
