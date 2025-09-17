terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ⚠️ Cost Explorer / CE APIs viven en us-east-1.
provider "aws" {
  region = var.region_ce
}

# ========== SNS para notificaciones ==========
resource "aws_sns_topic" "cost_anomaly_topic" {
  name = var.sns_topic_name
}

# Opción A: suscriptor por EMAIL (simple)
resource "aws_sns_topic_subscription" "email_sub" {
  count     = var.alert_to_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.cost_anomaly_topic.arn
  protocol  = "email"
  endpoint  = var.alert_to_email
}

# (Opcional) Opción B: si usas AWS Chatbot con Slack/Teams,
# suscríbelo a este topic desde la consola de Chatbot y omite email_sub.

# ========== MONITOR 1: por SERVICIO (DIMENSIONAL/SERVICE) ==========
resource "aws_ce_anomaly_monitor" "by_service" {
  name              = "anomaly-by-service"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

# ========== MONITOR 2: por TAG (CUSTOM/TAG:<clave>) ==========
# Requiere que recursos estén etiquetados y que la clave exista en Cost Explorer
resource "aws_ce_anomaly_monitor" "by_tag" {
  count         = var.enable_tag_monitor ? 1 : 0
  name          = "anomaly-by-tag-${var.tag_key}-${var.tag_value}"
  monitor_type  = "CUSTOM"
  # Agrupa por clave de tag y filtra por valor
  monitor_specification = jsonencode({
    Dimensions = {
      Key    = "TAG"
      Values = ["${var.tag_key}$${var.tag_value}"] # formato TAG_KEY$TAG_VALUE
    }
  })
}

# ========== SUSCRIPCIÓN (alertas) ==========
resource "aws_ce_anomaly_subscription" "sub" {
  name             = "cost-anomaly-subscription"
  # Umbral en USD del impacto previsto de la anomalía (ej.: 50 USD)
  threshold        = var.threshold_usd
  frequency        = var.frequency # DAILY | WEEKLY | IMMEDIATE
  monitor_arn_list = compact([
    aws_ce_anomaly_monitor.by_service.arn,
    length(aws_ce_anomaly_monitor.by_tag) > 0 ? aws_ce_anomaly_monitor.by_tag[0].arn : ""
  ])

  # A SNS topic (recomendado)
  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly_topic.arn
  }
}
