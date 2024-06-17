({ config, pkgs, modulesPath, lib, ... }:
{
  services.wyoming.piper = {
    servers = {
      "en" = {
        enable = true;
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
        model = "base";
        language = "en";
        uri = "tcp://0.0.0.0:10300";
        device = "cpu";
      };
    };
  };

  # needs access to /proc/cpuinfo
  systemd.services."wyoming-faster-whisper-en" = {
    serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      ProcSubset = lib.mkForce "all";
      ExecStart = lib.mkForce ''
        ${config.services.wyoming.faster-whisper.package}/bin/wyoming-faster-whipser \
          --data-dir $STATE_DIRECTORY \
          --download-dir $STATE_DIRECTORY \
          --uri tcp://0.0.0.0:10300 \
          --device cpu \
          --model base \
          --language en \
          --beam-size 4
      '';
    };
    requires = [ "network-online.target" ];
  };

  systemd.services."wyoming-piper-en".requires = [ "network-online.target" ];

  networking.firewall.allowedTCPPorts = [ 10300 10200 ];
})

