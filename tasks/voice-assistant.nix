({ config, pkgs, modulesPath, lib, ... }:
{
  services.wyoming.piper = {
    servers = {
      "en" = {
        enable = false;
        # see https://github.com/rhasspy/rhasspy3/blob/master/programs/tts/piper/script/download.py
        voice = "en_US-amy-medium";
        uri = "tcp://0.0.0.0:10200";
        speaker = 0;
      };
    };
  };

  services.wyoming.faster-whisper = {
    servers = {
      "en" = {
        enable = true;
        # see https://github.com/rhasspy/rhasspy3/blob/master/programs/asr/faster-whisper/script/download.py
        model = "small-int8";
        language = "en";
        uri = "tcp://0.0.0.0:10300";
        device = "cuda";
      };
    };
  };

  # needs access to /proc/cpuinfo
  systemd.services."wyoming-faster-whisper-en" = {
    serviceConfig.ProcSubset = lib.mkForce "all";
    after = lib.mkForce [ "network.target" ];
  };

  systemd.services."wyoming-piper-en".after = lib.mkForce [ "network.target" ];

  networking.firewall.allowedTCPPorts = [ 10300 10200 ];
})

