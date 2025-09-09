# eks-fargate-go-app

This project is a Go application deployed on Amazon EKS using Fargate. It is designed to be highly available across two availability zones and includes monitoring tools such as Grafana, Prometheus, and Loki.

## Project Structure

```
eks-fargate-go-app
├── src
│   └── main.go          # Entry point of the Go application
├── terraform
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Input variables for Terraform
│   ├── outputs.tf      # Output values from Terraform
│   ├── eks
│   │   ├── cluster.tf   # EKS cluster configuration
│   │   ├── fargate-profile.tf # Fargate profile configuration
│   │   └── node_groups.tf      # Node groups configuration
│   ├── monitoring
│   │   ├── grafana.tf   # Grafana setup for monitoring
│   │   ├── prometheus.tf # Prometheus setup for metrics
│   │   └── loki.tf      # Loki setup for log aggregation
│   └── networking
│       ├── vpc.tf       # VPC configuration
│       └── subnets.tf   # Subnets configuration
├── README.md            # Project documentation
└── .gitignore           # Files to ignore in version control
```

## Prerequisites

- AWS account
- Terraform installed
- Go installed

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   cd eks-fargate-go-app
   ```

2. Configure your AWS credentials.

3. Navigate to the `terraform` directory:
   ```
   cd terraform
   ```

4. Initialize Terraform:
   ```
   terraform init
   ```

5. Review and customize the `variables.tf` file as needed.

6. Apply the Terraform configuration:
   ```
   terraform apply
   ```

7. Once the infrastructure is set up, you can deploy the Go application.

## Usage

- Access the application through the EKS cluster endpoint.
- Use Grafana for monitoring the application and infrastructure.
- Prometheus will scrape metrics from the application.
- Loki will aggregate logs for querying through Grafana.

## High Availability

This setup ensures high availability by deploying resources across two availability zones.

## Monitoring

The project integrates Grafana, Prometheus, and Loki for comprehensive monitoring and logging capabilities.

## License

This project is licensed under the MIT License.