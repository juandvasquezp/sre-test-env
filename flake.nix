{
  description = "Entorno para desarrollo y despliegue de infraestructura en AWS usando Terraform";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Change this if you are on macOS (e.g., "x86_64-darwin" or "aarch64-darwin")
      system = "x86_64-linux"; 
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.terraform
          pkgs.awscli2
          pkgs.go
          pkgs.jq
          pkgs.opencode
	];

        shellHook = ''
          echo "Entorno listo con Terraform y AWS CLI"
          echo "Versión de Terraform: $(terraform version -json | jq -r '.terraform_version')"
          echo "Versión de AWS CLI: $(aws --version | awk '{print $1}')"
          echo "Versión de Go: $(go version | awk '{print $3}')"
        '';
      };
    };

}
