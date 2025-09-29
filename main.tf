# --- 1. Dependências do IAM para o SSM ---

# Policy de confiaça (Trust Policy) para o EC2 e SSM
data "aws_iam_policy_document" "assume_role_ssm" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
    }
  }
}

# IAM Role para ser anexada à instância EC2
resource "aws_iam_role" "ssm_role" {
  name               = "ssm-run-command-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ssm.json
}

# Anexa a política gerenciada do SSM
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile (Perfil de Instância) para o EC2
# Este recurso é usado para associar o Role ao EC2
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-run-command-profile"
  role = aws_iam_role.ssm_role.name
}

# Nota: Certifique-se de que sua instância EC2 existente/nova use
# aws_iam_instance_profile.ssm_instance_profile.name no parâmetro
# 'iam_instance_profile' da resource 'aws_instance'.


# --- 2. Criação de um Documento SSM Personalizado (Documento Command) ---

resource "aws_ssm_document" "test_run_command_document" {
  name            = "CustomRunShellScriptExample"
  document_type   = "Command"
  document_format = "JSON"
  content = jsonencode({
    schemaVersion = "1.2",
    description   = "Executa um comando shell simples de teste.",
    parameters    = {},
    runtimeConfig = {
      "aws:runShellScript" = {
        properties = [
          {
            id = "0.aws:runShellScript"
            runCommand = [
              "echo 'Iniciando execução do Run Command...'",
              "echo 'Data e hora atuais: $(date)' >> /tmp/run_command_test.txt",
              "echo 'Execução concluída! Confira o arquivo /tmp/run_command_test.txt'",
              "cat /tmp/run_command_test.txt"
            ]
          },
        ]
      }
    }
  })
}

# --- 3. Associação SSM para Executar o Comando ---

# Use 'aws_ssm_association' para agendar ou aplicar o comando.
# NOTA: Para uma execução imediata e única (como "Run Command"),
# o recurso 'aws_ssm_association' configura a "State Manager".
# Se você deseja uma execução *única* e *imediata* como o comando 'send-command'
# da CLI/Console, é mais complicado com o Terraform. A Association (Associação)
# criará um estado desejado (que pode ser executado uma vez, ou agendado).

# O exemplo abaixo cria uma associação que executa o comando uma única vez
# no momento da criação da association, pois não tem 'schedule_expression'.
# Você pode ter que esperar o estado da EC2 se tornar "Managed" pelo SSM (demora alguns minutos).

resource "aws_ssm_association" "run_test_command" {
  name = aws_ssm_document.test_run_command_document.name
  
  # Altere para o ID da sua instância EC2!
  targets {
    key    = "InstanceIds"
    values = ["i-xxxxxxxxxxxxxxxxx"] # SUBSTITUA PELO ID DA SUA INSTÂNCIA
  }

  # Executa o comando apenas uma vez no momento da criação da associação
  association_name = "RunTestCommand-OneTime"
  schedule_expression = "rate(7 days)" # Opcional: define um agendamento para reexecutar, se omitir, ele pode executar uma vez.
                                       # Sugestão: use 'rate(7 days)' ou 'cron(0 0 ? * * *)' se você não quiser
                                       # que ele re-execute imediatamente após falha, mas o SSM agent tentará reexecutar se a instância
                                       # estiver offline. Para uma execução única, o ideal seria não usar este recurso ou 
                                       # usar um módulo externo (como null_resource com local-exec para chamar a AWS CLI).

  # Define um limite para o número de instâncias/erros
  max_concurrency = "100%"
  max_errors      = "1"
}

# --- 4. Variáveis (Adicionar ao seu 'variables.tf') ---

/*
variable "ec2_instance_id" {
  description = "O ID da instância EC2 de destino para o SSM Run Command."
  type        = string
}
*/
