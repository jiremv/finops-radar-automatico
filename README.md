# AWS Cost Anomaly Detection – Terraform Stack

Monitorea y alerta **picos inusuales de costos** en AWS usando **Machine Learning** (Cost Anomaly Detection), desplegado con **Terraform**. Envía notificaciones a **SNS** (email o Slack/Teams vía **AWS Chatbot**). Incluye monitores por **Servicio** y (opcional) por **Tag**.

---

## 🧱 Arquitectura

```
+-------------------------+
|   AWS Cost Explorer     |
|  (Cost Anomaly Det.)    |
+-----------+-------------+
            |
   (Anomaly Monitors)
            |
            v
+-------------------------+         +----------------------+
|  Anomaly Subscription   +-------->+  Amazon SNS Topic   |
| (threshold/frequency)   |         +---------+-----------+
+-----------+-------------+                   |
            |                                 |
            |                         +-------+--------------------+
            |                         |   Subscribers (1..N)      |
            |                         |                            |
            |                         |  • Email (Email/JSON)      |
            |                         |  • AWS Chatbot (Slack/Teams) 
            |                         |  • HTTP/S, SQS, Lambda     |
            v                         |                            |
+-------------------------+           +----------------------------+
|   Terraform (IaC)       |
|  - aws_ce_anomaly_*     |
|  - aws_sns_*            |
+-------------------------+
```

---

## 📂 Contenido del módulo

- `main.tf`: recursos principales (SNS, monitors, subscription).
- `variables.tf`: variables para región, umbral, frecuencia, email, tag monitor.
- `outputs.tf`: ARNs útiles (topic, monitores).

> Este stack fija el **provider en `us-east-1`** porque las APIs de Cost Explorer/Anomaly Detection operan allí.

---

## 🚀 Despliegue

### 1) Requisitos previos
- Habilitar **Cost Explorer** en tu cuenta (Console → Cost Management → Cost Explorer → Enable).
- Terraform ≥ 1.5 y AWS provider ≥ 5.0.
- Permisos IAM para quien ejecuta Terraform:
  - `ce:*Anomaly*` (Create/Update/Delete Anomaly Monitor/Subscription)
  - `sns:*` sobre el topic (o al menos `sns:CreateTopic`, `sns:Subscribe`, `sns:Publish`…).

### 2) Variables principales (defaults razonables)

| Variable            | Descripción                                               | Default          |
|---------------------|-----------------------------------------------------------|------------------|
| `region_ce`         | Región para CE/Anomaly Detection                          | `us-east-1`      |
| `sns_topic_name`    | Nombre del SNS topic                                      | `cost-anomaly-topic` |
| `alert_to_email`    | Email para alertas (vacío = sin email)                    | `""`             |
| `threshold_usd`     | Umbral en USD del impacto previsto                        | `50`             |
| `frequency`         | `DAILY` \| `IMMEDIATE` \| `WEEKLY`                      | `DAILY`          |
| `enable_tag_monitor`| Crear monitor por Tag                                     | `false`          |
| `tag_key`           | Clave de tag (si `enable_tag_monitor=true`)               | `project`        |
| `tag_value`         | Valor de tag (si `enable_tag_monitor=true`)               | `finops`         |

### 3) Comandos

```bash
# 0) Clonar/copiar este proyecto y entrar al directorio
cd cost-anomaly-tf

# 1) Inicializar Terraform
terraform init

# 2) (Opcional) Ajustar variables rápidas al aplicar
terraform plan \
  -var="alert_to_email=finops@example.com" \
  -var="threshold_usd=30" \
  -var="frequency=IMMEDIATE" \
  -var="enable_tag_monitor=true" \
  -var="tag_key=env" \
  -var="tag_value=prod"

# 3) Aplicar cambios
terraform apply -auto-approve
```

> **Importante**: Si usas `alert_to_email`, SNS enviará un correo de **confirmación**. Debes aceptarlo para empezar a recibir alertas.

### 4) (Opcional) Slack/Teams con AWS Chatbot
- Crea una **Slack channel configuration** en AWS Chatbot y **suscribe** el **SNS topic** creado por Terraform.
- No necesitas email en ese caso.

### 5) Limpiar
```bash
terraform destroy
```

---

## 💸 Costos

| Componente                   | Costo típico |
|-----------------------------|--------------|
| **AWS Cost Anomaly Detection** | **$0** (gratis) |
| **Terraform**               | $0 en AWS (si lo ejecutas local/tu CI). Terraform Cloud/Enterprise puede tener su propio costo. |
| **Amazon SNS**              | **Free tier**: 1M *publish* / mes; Email gratis; HTTP/SQS/Lambda $0.60/M después del free tier; SMS con cargo por mensaje. |
| **AWS Chatbot**             | $0 |
| (Opc) CloudWatch Logs, S3, Lambda | Según uso; normalmente centavos si los empleas para integraciones extra. |

**Conclusión**: En la práctica, **no pagarás** por Anomaly Detection y **SNS suele ser gratis** si no envías >1M notificaciones/mes ni SMS masivos.

---

## 🔧 Operación y ajuste fino

- **Umbral (`threshold_usd`)**  
  - Producción suele usar ≥ $20–$100 (según tamaño del gasto).  
  - Dev/Test: umbral más bajo para sensibilidad.
- **Frecuencia (`frequency`)**  
  - `IMMEDIATE`: alerta apenas detecta anomalía (más ruidoso, útil en prod).  
  - `DAILY`/`WEEKLY`: consolidado, menos ruido.
- **Monitores**  
  - Por **Servicio** (`SERVICE`): vista macro.  
  - Por **Tag** (`TAG_KEY$TAG_VALUE`): foco por equipo/proyecto.  
  - (Multi-cuenta) Por **Cuenta Vinculada** (`LINKED_ACCOUNT`) en payer account (Organizations).
- **Propagación de tags a Cost Explorer**  
  - Asegura que tus **user-defined cost allocation tags** estén **activadas** en Billing → Cost Allocation Tags; tardan un tiempo en reflejarse.

---

## ✅ Verificación / Pruebas

1. **Ver salida**  
   Tras `apply`, revisa:
   - `sns_topic_arn`
   - `monitor_by_service_arn`
   - (si aplica) `monitor_by_tag_arn`

2. **Simular alertas**  
   - Baja el **umbral (`threshold_usd`)** temporalmente.  
   - Cambia `frequency` a `IMMEDIATE`.  
   - Genera una acción que incremente costo (p. ej., iniciar una instancia puntual) y monitorea Cost Explorer.  
   - **Ojo**: el motor de ML y la evaluación de anomalías no son instantáneos; el aprendizaje inicial puede requerir algo de historial.

---

## 🔐 Seguridad y buenas prácticas

- Limita quién puede editar este stack (principio de menor privilegio).
- Restringe `sns:Publish` a los producers necesarios.
- Si expones suscripciones HTTP, valida firma de SNS.
- Centraliza en cuenta pagadora (payer) si usas **AWS Organizations**.
- Integra con **ChatOps** (Slack/Teams) para visibilidad y reacción rápida.

---

## 🧩 Integración CI/CD (opcional)

- Usa GitHub Actions / CodeBuild para `terraform validate/plan/apply`.
- Workspaces de Terraform por **entorno** (`dev`, `prod`) con distintos umbrales/frecuencia.
- Guarda el **state** en S3 + DynamoDB (state locking) si aplicas en equipo.

---

## ❓ FAQ

**¿Necesito quedarme en `us-east-1`?**  
Sí, las APIs de Cost Explorer/Anomaly Detection están allí. El monitoreo abarca costos globales.

**¿Puedo tener múltiples suscripciones (email + Slack)?**  
Sí, agrega más `subscriber` (para Subscription via CE API) o más `aws_sns_topic_subscription` (para SNS directos). Recomendado centralizar todo en SNS y de ahí derivar.

**¿Qué diferencia con AWS Budgets?**  
Budgets usa **umbrales fijos** (planificados). Anomaly Detection usa **ML** para detectar **comportamientos anómalos** sin que tengas que predecirlos.

---

## 🧪 Variables de ejemplo (prod sensible)

```bash
terraform apply \
  -var="alert_to_email=finops@tu-empresa.com" \
  -var="threshold_usd=75" \
  -var="frequency=IMMEDIATE" \
  -var="enable_tag_monitor=true" \
  -var="tag_key=cost-center" \
  -var="tag_value=banking"
```
