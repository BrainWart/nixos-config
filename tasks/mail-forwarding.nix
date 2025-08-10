({ config, pkgs, modulesPath, lib, ... }:
{

  services.postfix = {
    enable = true;
    domain = "mcginnis.dev";
    transport = ''
      mcginnis.dev   smtp:[smtp-relay.gmail.com]:465
      *              discard:
    '';
    enableSubmissions = true;
    submissionsOptions = {
      smtp_sasl_auth_enable = "no";
      smtp_tls_security_level = "encrypt";
      smtp_tls_wrappermode = "yes";
      smtp_always_send_ehlo = "yes";
      smtp_helo_name = "home-dev";
    };
    extraConfig = ''
      inet_protocols = ipv4
      smtp_sasl_auth_enable = no
      smtp_tls_security_level = encrypt
      smtp_tls_wrappermode = yes
      smtp_always_send_ehlo = yes
      smtp_helo_name = home-dev
    '';
  };

})


