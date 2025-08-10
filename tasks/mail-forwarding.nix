({ config, pkgs, modulesPath, lib, ... }:
{

  services.postfix = {
    enable = true;
    domain = "mcginnis.dev";
    transport = ''
      mcginnis.dev   smtp:[smtp-relay.gmail.com]:465
      *              discard:
    '';
    extraConfig = ''
      smtp_sasl_auth_enable = no
      smtp_tls_security_level = encrypt
    '';
  };

})


