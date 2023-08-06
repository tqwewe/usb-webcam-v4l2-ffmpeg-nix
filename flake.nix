{
  description = "A flake for virtual webcam management";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }: let
    # Define the packages we'll need
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    v4l-utils = pkgs.v4l-utils;
    ffmpeg = pkgs.ffmpeg_5-full;

  in {
    packages.x86_64-linux.default = pkgs.writeShellScript "webcam" ''
      export PATH=${pkgs.lib.makeBinPath [ ffmpeg v4l-utils ]}:$PATH

      case "''$1" in
        setup)
          sudo modprobe -r v4l2loopback
          sudo modprobe v4l2loopback video_nr=5 card_label="GoPro" exclusive_caps=1
          ;;
        start)
          ffmpeg -f v4l2 -input_format mjpeg -r 30 -i /dev/video1 -vcodec rawvideo -pix_fmt rgb24 -r 30 -f v4l2 /dev/video5 > /dev/null 2>&1 &
          echo $! > /tmp/webcam_ffmpeg.pid
          ;;
        stop)
          if [ -f /tmp/webcam_ffmpeg.pid ]; then
            kill -9 $(cat /tmp/webcam_ffmpeg.pid) || echo "Failed to stop ffmpeg."
            rm /tmp/webcam_ffmpeg.pid
          else
            echo "ffmpeg is not running or no PID file found."
          fi
          ;;
        *)
          echo "Usage: webcam [setup|start|stop]"
          ;;
      esac
    '';
  };
}
