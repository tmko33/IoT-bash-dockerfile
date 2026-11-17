# Diagrama de arquitectura — Workshop 6

Pega el bloque de Mermaid en <https://mermaid.live>, revisa que renderice bien y
exporta una imagen PNG para guardarla en `04/06/capturas/01-arquitectura.png`.

```mermaid
flowchart TB
    U[Usuarios / Internet]

    subgraph VPC["VPC us-east-1"]
        subgraph Public["Subnets públicas"]
            ALB[Application Load Balancer<br/>80/443 · Multi-AZ]
            NAT[NAT Gateway]
        end

        subgraph App["Subnets privadas - aplicación"]
            ASG[Auto Scaling Group]
            EC2A[EC2 Flask · AZ a]
            EC2B[EC2 Flask · AZ b]
            EC2C[EC2 Flask · AZ c]
        end

        subgraph Data["Subnets privadas - datos"]
            RDS[(RDS PostgreSQL<br/>Multi-AZ)]
            S3[(S3 · documentos)]
        end
    end

    ECR[(ECR<br/>imagen Flask)]
    CW[CloudWatch<br/>métricas · logs · alarmas]

    U -->|HTTP/HTTPS| ALB
    ALB --> EC2A
    ALB --> EC2B
    ALB --> EC2C

    ASG -.->|mantiene| EC2A
    ASG -.->|mantiene| EC2B
    ASG -.->|mantiene| EC2C

    EC2A --> RDS
    EC2B --> RDS
    EC2C --> RDS

    EC2A --> S3
    EC2B --> S3
    EC2C --> S3

    EC2A --> NAT
    EC2B --> NAT
    EC2C --> NAT

    ECR -.->|docker pull| EC2A
    ECR -.->|docker pull| EC2B
    ECR -.->|docker pull| EC2C

    CW -.-> ALB
    CW -.-> EC2A
    CW -.-> RDS
```

## Lectura del diagrama

- **Público:** solo el ALB (80/443) y el NAT Gateway para salida a Internet.
- **Privado:** las EC2 de Flask, RDS, S3 (acceso por IAM) y ECR.
- **Escalable:** ALB, Auto Scaling Group y las réplicas de Flask.
- **Persistente:** RDS Multi-AZ, S3 con versioning y ECR con imágenes versionadas.
- **Monitoreado:** CloudWatch (métricas, logs y alarmas), access logs del ALB,
  X-Ray/ADOT y GuardDuty/Security Hub.
- **Seguridad:** subnets privadas, Security Groups encadenados, IAM Roles,
  Secrets Manager, TLS/ACM y WAF.
