terraform {
  # Este backend es de pruebas, para un entorno de producción hay que reemplazar por un backend remoto
  backend "local" {
    path = "terraform.tfstate"
  }
}
