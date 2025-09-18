variable "region_ce" {
  description = "Región para CE/Anomaly Detection (debe ser us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "sns_topic_name" {
  description = "Nombre del SNS topic para las alertas"
  type        = string
  default     = "cost-anomaly-topic"
}

variable "alert_to_email" {
  description = "Email para recibir alertas (obligatorio si usas DAILY/WEEKLY, dejar vacío si no deseas email)"
  type        = string
  default     = "paulrivera34@gmail.com"
}

variable "threshold_usd" {
  description = "Umbral (USD) de impacto previsto para alertar"
  type        = number
  default     = 25
}

variable "frequency" {
  description = "Frecuencia de notificación: DAILY | WEEKLY | IMMEDIATE"
  type        = string
  default     = "DAILY"
}

variable "enable_tag_monitor" {
  description = "Crear monitor por TAG (true/false)"
  type        = bool
  default     = false
}

variable "tag_key" {
  description = "Clave de la etiqueta a monitorear (si enable_tag_monitor=true)"
  type        = string
  default     = "project"
}

variable "tag_value" {
  description = "Valor de la etiqueta a monitorear (si enable_tag_monitor=true)"
  type        = string
  default     = "finops"
}
