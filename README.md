# Production-Grade QR Code Generator API on Azure Functions

---

# 📘 Introduction / Overview

This project is a **production-grade reference implementation** for deploying a **Node.js TypeScript Azure Function** using **modern DevOps and security best practices**.

It demonstrates how to build, secure, and deploy a serverless backend on Azure using:

- **Terraform** for infrastructure as code
- **GitHub Actions** for automated CI/CD
- **Azure Entra ID (OIDC)** for passwordless authentication
- **Azure Key Vault** for secure secrets management
- **Deployment slots** for zero-downtime releases

The goal of this repository is not just to deploy an Azure Function, but to showcase **how Azure Functions should be deployed in real-world, production environments**—with strong security boundaries, reproducible infrastructure, and fully automated delivery pipelines.

---

# ✨ Features

This project provides a **production-ready reference architecture** for deploying **Node.js TypeScript Azure Functions** with secure, automated CI/CD on Azure.

---

### 🔐 Secure, Passwordless Authentication

- GitHub Actions authenticates to Azure using **OIDC (Federated Identity)**
- No client secrets or credentials stored in GitHub
- Aligns with modern cloud security best practices

---

### 🏗️ Infrastructure as Code (Terraform)

- Fully automated Azure infrastructure provisioning
- Repeatable, version-controlled, and environment-aware
- Creates Function App, Key Vault, Storage, slots, and identities

---

### 🔑 Centralized Secrets Management

- All secrets stored in **Azure Key Vault**
- Secure access via managed identities and RBAC
- No secrets hardcoded in code or pipelines

---

### 🚀 Automated CI/CD with GitHub Actions

- Triggered on every push to `main`
- Build, package, and deploy TypeScript functions automatically
- Azure login handled securely via OIDC

---

### 🔄 Zero-Downtime Deployments

- Uses **staging → production slot swapping**
- Health checks before promoting releases
- Prevents broken deployments from reaching users

---

### 📦 Modern Serverless Stack

- Azure Functions v4
- Node.js 22 + TypeScript
- Optimized for scalability and maintainability

---

### 🛡️ Enterprise-Ready by Design

- Least-privilege RBAC
- Separate identities for Terraform and CI/CD
- Clean, scalable, and extensible architecture

---

This repository is ideal as a **real-world baseline** for building secure, scalable, and automated Azure Function deployments.

# 🏗️ Architecture Overview

This project uses a secure, production-grade architecture for deploying
Node.js TypeScript Azure Functions with automated CI/CD.

![Architecture Diagram](https://github.com/Nikhil-Mhatre/azure-qr-code-generator-ci-cd/blob/main/docs/architecture_diagram.png)

### High-level design

- Infrastructure is provisioned using Terraform
- GitHub Actions deploys code using OIDC (no secrets)
- Secrets are stored in Azure Key Vault
- Deployments use staging slots for zero downtime

📘 **Detailed architecture documentation:**

# 📦 Prerequisites

Ensure the following tools are installed and configured:

- Azure CLI (`az`)
- Terraform (v1.x recommended)
- Git
- An active Azure subscription
- GitHub account with repository access

---

# 📥 Clone the Repository

```bash
git clone git@github.com:Nikhil-Mhatre/azure-qr-code-generator-ci-cd.git
cd azure-qr-code-generator-ci-cd

```

---

# 🔐 Creating a Terraform Service Principal (Azure Portal)

Terraform uses an **Azure Service Principal** to authenticate and manage Azure resources securely.

## 1️⃣ Create an App Registration

1. Go to **Azure Portal**
2. Navigate to
   **Azure Entra ID → App registrations**
3. Click **New registration**
4. Fill in:

   * **Name:** `terraform-sp`
   * **Supported account types:** Single tenant
5. Click **Register**

After creation, note down:

* **Application (client) ID**
* **Directory (tenant) ID**

---

## 2️⃣ Create a Client Secret

1. Inside the App Registration, go to
   **Certificates & secrets**
2. Under **Client secrets**, click **New client secret**
3. Provide:

   * **Description:** `terraform-secret`
   * **Expiry:** 6 or 12 months (recommended)
4. Click **Add**
5. **Copy the secret value immediately it will client secret** (it will not be shown again)

![Architecture Diagram](https://github.com/Nikhil-Mhatre/azure-qr-code-generator-ci-cd/blob/main/docs/Terraform_SP_creation.png)

---

## 3️⃣ Assign Role at Subscription Level

1. Go to **Subscriptions**
2. Select your target subscription
3. Navigate to
   **Access control (IAM)**
4. Click **Add → Add role assignment**
5. Choose:

   * **Role:** `Contributor`
6. Click **Next**
7. Under **Members**, select:

   * **Assign access to:** User, group, or service principal
   * **Select members:** `terraform-sp`
8. Click **Review + assign**

## Note: Create same steps for creating "User Access Administrator" role
✅ The Service Principal now has permission to manage Azure resources.

![Architecture Diagram](https://github.com/Nikhil-Mhatre/azure-qr-code-generator-ci-cd/blob/main/docs/contributor_and_user_access_role_assignment.png)

---

# ⚙️ Configure Environment Variables

Create a `.env` file (refer to `.env.sample`) and ensure **all Azure secrets are prefixed with `ARM_`**.

```bash
ARM_CLIENT_ID="<client_id>"
ARM_CLIENT_SECRET="<client_secret>"
ARM_TENANT_ID="<tenant>"
ARM_SUBSCRIPTION_ID="<subscription_id>"

```

### GitHub Token (Required)

Generate a **Classic Personal Access Token**:

> GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (Classic)

![Architecture Diagram](https://github.com/Nikhil-Mhatre/azure-qr-code-generator-ci-cd/blob/main/docs/github_token_generation.png)

Add it to `.env` using the Terraform variable prefix:

```bash
TF_VAR_github_token=xxxxxxxxxxxxxxxx

```

> ℹ️ Terraform automatically loads variables prefixed with TF_VAR_.
> 

---

## 🧪 Load and Verify Environment Variables

```bash
set -a
source .env
set +a

```

Verify:

```bash
echo $ARM_CLIENT_ID

```

---

# 🏗️ Provision Infrastructure with Terraform

### 1️⃣ Navigate to Infrastructure Directory

```bash
cd infra

```

### 2️⃣ Create `terraform.tfvars`

Use `terraform.sample.tfvars` as reference:

```hcl
project_name = "qrcode"
environment  = "prod"
location     = "centralindia"
github_owner = "YOUR_GITHUB_USERNAME"
github_repo  = "YOUR_REPO_NAME"

```

---

### 3️⃣ Run Terraform

```bash
terraform init
terraform plan
terraform apply -auto-approve

```

---

# 🚀 Deploy Backend via GitHub Actions

Once infrastructure is ready:

```bash
cd ../.backend

```

- Modify backend code as needed
- Push changes to the `main` branch

This will automatically trigger the **GitHub Actions workflow** and deploy the backend to **Azure Functions**.

---


## 🧪 Testing the Azure Function with Postman

This Azure Function exposes two HTTP endpoints that can be tested using **Postman** or any HTTP client.

## ❤️ Health Check Endpoint

Use this endpoint to verify that the Function App is running correctly.

### Endpoint

```
GET /health
```

### Full URL

```
GET https://<function-app-name>.azurewebsites.net/api/health
```

### Expected Response

```json
{
  "status": "ok"
}
```

✅ This endpoint is also used by the CI/CD pipeline to validate deployments before slot swapping.

---

## 🔳 Generate QR Code Endpoint

This endpoint generates a QR code for a given URL.

### Endpoint

```
POST /generate-qr-code
```

### Full URL

```
POST https://<function-app-name>.azurewebsites.net/api/generate-qr-code
```

---

### 📤 Request (Postman Setup)

**Method:** `POST`
**Headers:**

```
Content-Type: application/json
```

**Body (raw → JSON):**

```json
{
  "url": "https://example.com"
}
```

---

### 📥 Response

On success, the API returns a QR code (for example, as a base64 string or image URL, depending on implementation).

Example:

```json
{
  "qrCode": "<base64-encoded-qr-code>"
}
```

You can:

* Render the QR code in a frontend
* Decode the Base64 string into an image
* Save it locally for further use

---



# 🤝 Contributing

Contributions are welcome and appreciated! Please follow the steps below to get started quickly.

---

### 🛠️ How to Contribute

1. **Fork the repository**
2. **Clone your fork**
    
    ```bash
    git clone git@github.com:<your-username>/<repo-name>.git
    cd <repo-name>
    
    ```
    
3. **Create a feature branch**
    
    ```bash
    git checkout -b feature/your-change
    
    ```
    
4. **Make your changes**
    - Follow existing code and Terraform conventions
    - Keep changes focused and minimal
5. **Commit your work**
    
    ```bash
    git commit -m "feat: meaningful description"
    
    ```
    
6. **Push to your fork**
    
    ```bash
    git push origin feature/your-change
    
    ```
    
7. **Open a Pull Request** against the `main` branch

---

### ✅ Contribution Guidelines

- Ensure CI checks pass
- Avoid committing secrets or environment files
- Update documentation if behavior changes
- One logical change per PR is preferred

---

Thanks for helping improve this project 🚀

# 📜 License

This project is licensed under the MIT License.
