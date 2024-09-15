{ inputs, lib, config, pkgs, ... }: {
  services.ollama = {
    enable = true;
    user = "ollama";
    host = "0.0.0.0";
    loadModels = [ "llama3.1:8b" ];
    models = "/persist/ollama/models";
    home = "/persist/ollama";
    acceleration = "cuda";
    package = pkgs.ollama.override {
      config.rocmSupport = false;
      config.cudaSupport = config.nixpkgs.config.cudaSupport;
    };
    environmentVariables = lib.optionalAttrs config.nixpkgs.config.cudaSupport
      {
        CUDA_PATH = "${pkgs.cudatoolkit}";
      } // {
      OLLAMA_ORIGINS = "http://192.168.20.87:3000";
    };
  };
  services.nextjs-ollama-llm-ui = {
    enable = true;
    hostname = "0.0.0.0";
    ollamaUrl = "http://192.168.20.87:${toString config.services.ollama.port}";
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ollama.port
    config.services.nextjs-ollama-llm-ui.port
  ];
}

